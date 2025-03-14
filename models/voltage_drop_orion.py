from PySide6.QtCore import Slot, Signal, Property, QObject, QAbstractTableModel, Qt, QUrl
import pandas as pd
import math
import os
import json  # Add this import
# Add imports for PDF generation
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_CENTER

class VoltageDropTableModel(QAbstractTableModel):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = []
        self._headers = [
            'Size', 
            'Material', 
            'Cores', 
            'mV/A/m', 
            'Rating', 
            'V-Drop', 
            'Drop %', 
            'Status'
        ]
        
    def rowCount(self, parent=None):
        return len(self._data)
        
    def columnCount(self, parent=None):
        return len(self._headers)
        
    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
            
        if role == Qt.DisplayRole:
            value = self._data[index.row()][index.column()]
            if isinstance(value, float):
                if index.column() == 6:  # Drop % column
                    return f"{value:.1f}%"
                return f"{value:.1f}"
            return str(value)
            
        if role == Qt.BackgroundRole and index.column() == 7:
            status = self._data[index.row()][6]  # Drop %
            if status > 5:
                return Qt.red
            return Qt.green
            
    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    def update_data(self, data):
        self.beginResetModel()
        self._data = data
        self.endResetModel()

class VoltageDrop(QObject):
    """
    Voltage drop calculator using mV/A/m method according to AS/NZS 3008.
    
    Features:
    - Load cable data from CSV
    - Calculate voltage drop using mV/A/m values
    - Support for different installation methods
    - Temperature correction factors
    - Grouping factors
    """
    
    dataChanged = Signal()
    voltageDropCalculated = Signal(float)
    cablesChanged = Signal()  # Add signal for cables list
    methodsChanged = Signal()  # Add signal for installation methods
    tableDataChanged = Signal()
    conductorChanged = Signal()
    coreTypeChanged = Signal()
    voltageOptionsChanged = Signal()  # Add new signal
    selectedVoltageChanged = Signal()  # Add new signal
    diversityFactorChanged = Signal()  # Add new signal
    totalLoadChanged = Signal(float)  # Add new signal
    currentChanged = Signal(float)  # Add new signal
    saveSuccess = Signal(bool)
    saveStatusChanged = Signal(bool, str)  # Add new signal with status and message
    numberOfHousesChanged = Signal(int)  # Add new signal
    admdEnabledChanged = Signal(bool)    # Add new signal
    fuseSizeChanged = Signal(str)  # Add new signal for fuse size changes
    conductorRatingChanged = Signal(float)  # Add new signal for conductor rating changes
    combinedRatingChanged = Signal(str)  # Add new signal for combined rating info
    chartSaved = Signal(bool, str)  # Add signal for chart save status
    grabRequested = Signal(str, float)  # Signal with filepath and scale factors
    tableExportStatusChanged = Signal(bool, str)  # Add new signal for table export status
    # Add new signal for PDF export status
    pdfExportStatusChanged = Signal(bool, str)
    tablePdfExportStatusChanged = Signal(bool, str)  # Add new signal for table PDF export

    def __init__(self):
        super().__init__()
        self._cable_data = None
        self._current = 0.0
        self._length = 0.0
        self._selected_cable = None
        self._voltage_drop = 0.0
        self._temperature = 25  # Default temp in °C
        self._installation_method = "D1 - Underground direct buried"
        self._grouping_factor = 1.0
        self._available_cables = []  # Add property storage
        self._installation_methods = [
            "A1 - Enclosed in thermal insulation",
            "A2 - Enclosed in wall/ceiling",
            "B1 - Enclosed in conduit in wall",
            "B2 - Enclosed in trunking/conduit",
            "C - Clipped direct",
            "D1 - Underground direct buried",
            "D2 - Underground in conduit",
            "E - Free air",
            "F - Cable tray/ladder/cleated",
            "G - Spaced from surface"
        ]
        self._conductor_material = "Al"
        self._core_type = "3C+E"
        self._conductor_types = ["Cu", "Al"]
        self._core_configurations = ["1C+E", "3C+E"]
        
        # Load separate CSV files for different configurations
        self._cable_data_cu_1c = None
        self._cable_data_cu_3c = None
        self._cable_data_al_1c = None
        self._cable_data_al_3c = None
        self._load_all_cable_data()
        self._table_model = VoltageDropTableModel()
        self._load_cable_data()
        self._voltage_options = ["230V", "415V"]
        self._selected_voltage = "415V"
        self._voltage = 415.0
        self._diversity_factor = 1.0
        self._diversity_factors = None
        self._load_diversity_factors()
        self._num_houses = 1
        self._total_kva = 0.0
        self._admd_enabled = False
        self._admd_factor = 1.5  # ADMD factor for neutral calculations
        self._calculation_results = []  # Store calculation history
        self._fuse_sizes_data = None
        self._current_fuse_size = "N/A"
        self._conductor_rating = 0.0
        self._combined_rating_info = "N/A"
        self._load_fuse_sizes_data()

    def _load_all_cable_data(self):
        """Load all cable data variants."""
        try:
            self._cable_data_cu_1c = pd.read_csv("data/cable_data_cu_1c.csv")
            self._cable_data_cu_3c = pd.read_csv("data/cable_data_cu_3c.csv")
            self._cable_data_al_1c = pd.read_csv("data/cable_data_al_1c.csv")
            self._cable_data_al_3c = pd.read_csv("data/cable_data_al_3c.csv")
            self._update_current_cable_data()
        except Exception as e:
            print(f"Error loading cable data: {e}")

    def _update_current_cable_data(self):
        """Update active cable data based on current selections."""
        if self._conductor_material == "Cu":
            if self._core_type == "1C+E":
                self._cable_data = self._cable_data_cu_1c
            else:
                self._cable_data = self._cable_data_cu_3c
        else:  # Aluminum
            if self._core_type == "1C+E":
                self._cable_data = self._cable_data_al_1c
            else:
                self._cable_data = self._cable_data_al_3c

        self._available_cables = self._cable_data['size'].tolist()
        self.cablesChanged.emit()
        
        # Update selected cable if needed
        if self._available_cables:
            self._selected_cable = self._cable_data.iloc[0]
            self._calculate_voltage_drop()

    def _load_cable_data(self):
        """Load cable data from CSV file containing mV/A/m values."""
        try:
            self._cable_data = pd.read_csv("data/cable_data_mv.csv")
            self._available_cables = self._cable_data['size'].tolist()
            # Select first cable as default
            if self._available_cables:
                self._selected_cable = self._cable_data.iloc[0]
                # print(f"Selected default cable: {self._selected_cable['size']}")
            self.cablesChanged.emit()
        except Exception as e:
            print(f"Error loading cable data: {e}")
            self._cable_data = pd.DataFrame()
            self._available_cables = []

    def _load_diversity_factors(self):
        """Load diversity factors from CSV file."""
        try:
            df = pd.read_csv("data/diversity_factor.csv")
            # Rename columns to match expected names
            df.columns = ['houses', 'factor']
            self._diversity_factors = df
            # print("Loaded diversity factors:", self._diversity_factors)
        except Exception as e:
            print(f"Error loading diversity factors: {e}")
            self._diversity_factors = pd.DataFrame({'houses': [1], 'factor': [1.0]})

    def _get_diversity_factor(self, num_houses):
        """Get diversity factor based on number of houses."""
        try:
            if self._diversity_factors is None:
                return 1.0

            df = self._diversity_factors
            print(f"Looking up diversity factor for {num_houses} houses")
            
            # Find exact match first
            exact_match = df[df['houses'] == num_houses]
            if not exact_match.empty:
                factor = float(exact_match.iloc[0]['factor'])
                print(f"Found exact match: {factor}")
                return factor

            # If no exact match, interpolate
            if num_houses <= df['houses'].min():
                factor = float(df.iloc[0]['factor'])
            elif num_houses >= df['houses'].max():
                factor = float(df.iloc[-1]['factor'])
            else:
                # Find surrounding values
                idx = df['houses'].searchsorted(num_houses)
                h1, h2 = df['houses'].iloc[idx-1:idx+1]
                f1, f2 = df['factor'].iloc[idx-1:idx+1]
                
                # Linear interpolation
                factor = f1 + (f2 - f1) * (num_houses - h1) / (h2 - h1)

            print(f"Calculated diversity factor: {factor}")
            self._diversity_factor = factor
            self.diversityFactorChanged.emit()
            return factor

        except Exception as e:
            print(f"Error calculating diversity factor: {e}")
            return 1.0

    def _load_fuse_sizes_data(self):
        """Load network fuse size data from CSV."""
        try:
            self._fuse_sizes_data = pd.read_csv("data/network_fuse_sizes.csv")
            print(f"Loaded {len(self._fuse_sizes_data)} fuse size entries")
        except Exception as e:
            print(f"Error loading fuse size data: {e}")
            self._fuse_sizes_data = pd.DataFrame(columns=["Material", "Size (mm2)", "Network Fuse Size (A)"])

    def _update_fuse_size(self):
        """Update fuse size based on current cable selection."""
        if self._fuse_sizes_data is None or self._selected_cable is None:
            self._current_fuse_size = "N/A"
            self._combined_rating_info = "N/A"
            self.fuseSizeChanged.emit(self._current_fuse_size)
            self.combinedRatingChanged.emit(self._combined_rating_info)
            return
            
        try:
            # Get current size and material
            if isinstance(self._selected_cable['size'], pd.Series):
                cable_size = float(self._selected_cable['size'].iloc[0])
            else:
                cable_size = float(self._selected_cable['size'])
                
            # Get conductor rating
            if isinstance(self._selected_cable['max_current'], pd.Series):
                self._conductor_rating = float(self._selected_cable['max_current'].iloc[0])
            else:
                self._conductor_rating = float(self._selected_cable['max_current'])
            
            self.conductorRatingChanged.emit(self._conductor_rating)
            
            # Look up the fuse size
            match = self._fuse_sizes_data[
                (self._fuse_sizes_data['Material'] == self._conductor_material) & 
                (self._fuse_sizes_data['Size (mm2)'] == cable_size)
            ]
            
            if not match.empty:
                fuse_size = f"{match.iloc[0]['Network Fuse Size (A)']} A"
                self._current_fuse_size = fuse_size
                print(f"Found fuse size {fuse_size} for {self._conductor_material} {cable_size} mm²")
            else:
                self._current_fuse_size = "Not specified"
                print(f"No matching fuse size for {self._conductor_material} {cable_size} mm²")
                
            # Create combined rating info
            if self._current_fuse_size != "N/A" and self._current_fuse_size != "Not specified" and self._conductor_rating > 0:
                self._combined_rating_info = f"{self._current_fuse_size} / {self._conductor_rating:.0f} A"
            elif self._conductor_rating > 0:
                if self._current_fuse_size == "Not specified":
                    self._combined_rating_info = f"No fuse / {self._conductor_rating:.0f} A"
                else:
                    self._combined_rating_info = f"{self._conductor_rating:.0f} A"
            else:
                self._combined_rating_info = "N/A"
                
            self.fuseSizeChanged.emit(self._current_fuse_size)
            self.combinedRatingChanged.emit(self._combined_rating_info)
            
        except Exception as e:
            print(f"Error updating fuse size and rating: {e}")
            self._current_fuse_size = "Error"
            self._combined_rating_info = "Error"
            self.fuseSizeChanged.emit(self._current_fuse_size)
            self.combinedRatingChanged.emit(self._combined_rating_info)

    @Property(float, notify=totalLoadChanged)
    def totalKva(self):
        """Get total KVA value."""
        return self._total_kva

    @Property(float, notify=currentChanged)
    def current(self):
        """Get the current value in amperes."""
        return self._current

    @Slot(float)
    def setCurrent(self, current):
        """Set the operating current."""
        if self._current != current:
            self._current = current
            self.currentChanged.emit(current)
            self._calculate_voltage_drop()
    
    @Slot(float)
    def setLength(self, length):
        """Set the cable length in meters."""
        self._length = length
        self._calculate_voltage_drop()
    
    @Slot(str)
    def selectCable(self, cable_size):
        """Select cable size and get corresponding mV/A/m value."""
        if self._cable_data is not None:
            try:
                cable_data = self._cable_data[self._cable_data['size'] == float(cable_size)]
                if not cable_data.empty:
                    self._selected_cable = cable_data.iloc[0]
                    print(f"Selected cable: {cable_size}, mV/A/m: {self._selected_cable['mv_per_am']}")
                    self._calculate_voltage_drop()
                    self._update_fuse_size()  # Add this line
                else:
                    print(f"Cable size {cable_size} not found in data")
            except ValueError:
                print(f"Invalid cable size format: {cable_size}")

    @Slot(float)
    def setTemperature(self, temp):
        """Set operating temperature and apply correction factor."""
        self._temperature = temp
        self._calculate_voltage_drop()
    
    @Slot(str)
    def setInstallationMethod(self, method):
        """Set installation method and apply corresponding factor."""
        self._installation_method = method
        self._calculate_voltage_drop()
    
    @Slot(float)
    def setGroupingFactor(self, factor):
        """Set grouping factor for multiple circuits."""
        self._grouping_factor = factor
        self._calculate_voltage_drop()
    
    @Slot(str)
    def setConductorMaterial(self, material):
        """Set conductor material (Cu/Al)."""
        if material in self._conductor_types and material != self._conductor_material:
            self._conductor_material = material
            self._update_current_cable_data()
            self.conductorChanged.emit()
            self._update_fuse_size()  # Add this line

    @Slot(str)
    def setCoreType(self, core_type):
        """Set core configuration (1C+E/3C+E)."""
        if core_type in self._core_configurations and core_type != self._core_type:
            self._core_type = core_type
            self._update_current_cable_data()
            self.coreTypeChanged.emit()

    @Slot(float)
    def setTotalKVA(self, total_kva):
        """Set total kVA and recalculate current with diversity.
        
        Applies diversity factor to number of houses rather than kVA:
        total_adjusted = kva_per_house * num_houses * diversity_factor
        """
        if total_kva > 0:
            self._total_kva = total_kva
            kva_per_house = total_kva / self._num_houses if self._num_houses > 0 else total_kva
            diversity_factor = self._get_diversity_factor(self._num_houses)
            
            # Apply diversity to number of houses instead of total kVA
            adjusted_kva = kva_per_house * self._num_houses * diversity_factor
            
            print(f"KVA per house: {kva_per_house:.2f}, Houses: {self._num_houses}, "
                  f"Diversity: {diversity_factor}, Adjusted: {adjusted_kva:.2f}")
            
            current = (adjusted_kva * 1000) / (self._voltage * math.sqrt(3))
            self.setCurrent(current)

    @Slot(int)
    def setNumberOfHouses(self, num_houses):
        """Set number of houses and update diversity factor."""
        if num_houses > 0 and self._num_houses != num_houses:
            self._num_houses = num_houses
            self._diversity_factor = self._get_diversity_factor(num_houses)
            print(f"Updated houses to {num_houses}, diversity factor: {self._diversity_factor}")
            self.numberOfHousesChanged.emit(num_houses)  # Emit signal
            self.diversityFactorChanged.emit()
            # Recalculate if we have a total kVA value
            if self._total_kva > 0:
                self.setTotalKVA(self._total_kva)

    @Slot(float)
    def setDiversityFactor(self, factor):
        """Set diversity factor for multiple houses."""
        if 0 < factor <= 1:
            self._diversity_factor = factor
            self.dataChanged.emit()

    @Slot(str)
    def setSelectedVoltage(self, voltage_option):
        """Set system voltage (230V or 415V)."""
        if voltage_option in self._voltage_options and voltage_option != self._selected_voltage:
            self._selected_voltage = voltage_option
            self._voltage = 230.0 if voltage_option == "230V" else 415.0
            self._calculate_voltage_drop()
            self.selectedVoltageChanged.emit()
            self.dataChanged.emit()

    @Slot(bool)
    def setADMDEnabled(self, enabled):
        """Enable/disable ADMD factor."""
        if self._admd_enabled != enabled:
            self._admd_enabled = enabled
            self._calculate_voltage_drop()
            self.admdEnabledChanged.emit(enabled)  # Emit signal
            print(f"ADMD {'enabled' if enabled else 'disabled'}")

    @Property(bool, notify=admdEnabledChanged)  # Update property decorator
    def admdEnabled(self):
        """Get ADMD enabled state."""
        return self._admd_enabled

    @Property('QVariantList', notify=voltageOptionsChanged)
    def voltageOptions(self):
        """Get available voltage options."""
        return self._voltage_options

    @Property(str, notify=selectedVoltageChanged)
    def selectedVoltage(self):
        """Get currently selected voltage option."""
        return self._selected_voltage

    @Property(float, notify=diversityFactorChanged)
    def diversityFactor(self):
        """Get current diversity factor."""
        return self._diversity_factor

    @Property(int, notify=numberOfHousesChanged)  # Update property decorator
    def numberOfHouses(self):
        """Get current number of houses."""
        return self._num_houses

    @Slot(float, int)
    def calculateTotalLoad(self, kva_per_house: float, num_houses: int):
        """Calculate total load and current based on per-house KVA with diversity."""
        try:
            # Calculate raw total kVA
            raw_total_kva = kva_per_house * num_houses
            
            # Get diversity factor and calculate adjusted kVA
            diversity_factor = self._get_diversity_factor(num_houses)
            adjusted_kva = raw_total_kva * diversity_factor
            
            print(f"Raw total: {raw_total_kva:.2f} kVA")
            print(f"Diversity factor: {diversity_factor}")
            print(f"Adjusted total: {adjusted_kva:.2f} kVA")
            
            # Store values
            self._num_houses = num_houses
            self._total_kva = adjusted_kva
            
            # Emit signal for QML binding
            self.totalLoadChanged.emit(adjusted_kva)
            
            # Calculate current based on voltage selection and adjusted kVA
            if self._voltage == 230.0:  # Single phase
                current = (adjusted_kva * 1000) / self._voltage  # P = VI
                print(f"Single phase current: {current:.1f}A")
            else:  # Three phase (415V)
                current = (adjusted_kva * 1000) / (self._voltage * math.sqrt(3))  # P = √3 × VI
                print(f"Three phase current: {current:.1f}A")
            
            self.setCurrent(current)
            return adjusted_kva
            
        except Exception as e:
            print(f"Error calculating total load: {e}")
            return 0.0

    @Slot()
    def reset(self):
        """Reset calculator to default values."""
        # Reset core valuess
        self._current = 0.0
        self._length = 0.0
        self._temperature = 25
        self._installation_method = "D1 - Underground direct buried"
        self._grouping_factor = 1.0
        self._conductor_material = "Al"
        self._core_type = "3C+E"
        self._selected_voltage = "415V"
        self._voltage = 415.0
        self._num_houses = 1
        self._total_kva = 0.0
        self._admd_enabled = False
        self._voltage_drop = 0.0
        self._current_fuse_size = "N/A"
        self._conductor_rating = 0.0
        self._combined_rating_info = "N/A"
        
        # Clear table data
        if self._table_model:
            self._table_model.update_data([])
        
        # Emit all signals
        self.dataChanged.emit()
        self.currentChanged.emit(self._current)
        self.conductorChanged.emit()
        self.coreTypeChanged.emit()
        self.selectedVoltageChanged.emit()
        self.totalLoadChanged.emit(self._total_kva)
        self.voltageDropCalculated.emit(self._voltage_drop)
        self.tableDataChanged.emit()
        self.fuseSizeChanged.emit(self._current_fuse_size)
        self.conductorRatingChanged.emit(self._conductor_rating)
        self.combinedRatingChanged.emit(self._combined_rating_info)

    @Slot()
    def saveCurrentCalculation(self):
        """Save current calculation results."""
        try:
            if self._selected_cable is None or self._voltage_drop == 0:
                self.saveStatusChanged.emit(False, "No calculation to save")
                return

            timestamp = pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S")
            result = {
                'timestamp': timestamp,
                'voltage_system': self._selected_voltage,
                'kva_per_house': self._total_kva / self._num_houses if self._num_houses > 0 else self._total_kva,
                'num_houses': self._num_houses,
                'diversity_factor': self._diversity_factor,
                'total_kva': self._total_kva,
                'current': self._current,
                'cable_size': float(self._selected_cable['size'].iloc[0]) if isinstance(self._selected_cable['size'], pd.Series) else float(self._selected_cable['size']),
                'conductor': self._conductor_material,
                'core_type': self._core_type,
                'length': self._length,
                'voltage_drop': self._voltage_drop,
                'drop_percent': (self._voltage_drop / self._voltage) * 100,
                'admd_enabled': self._admd_enabled
            }
            
            # Ensure the directory exists
            os.makedirs('results', exist_ok=True)
            
            # Save to CSV in results directory
            filepath = 'results/calculations_history.csv'
            df = pd.DataFrame([result])
            file_exists = os.path.isfile(filepath)
            df.to_csv(filepath, mode='a', header=not file_exists, index=False)
            
            success_msg = f"Calculation saved to {filepath}"
            print(success_msg)
            self.saveStatusChanged.emit(True, success_msg)
            
        except Exception as e:
            error_msg = f"Error saving calculation: {e}"
            print(error_msg)
            self.saveStatusChanged.emit(False, error_msg)

    @Slot(str, float)
    def saveChart(self, filepath, scale=2.0):
        """Save chart as image with optional scale factor."""
        try:
            # Show file dialog if filepath is empty or None
            if not filepath:
                from PySide6.QtWidgets import QFileDialog
                import os
                
                # Get absolute path to results directory
                results_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'results'))
                os.makedirs(results_dir, exist_ok=True)
                
                # Create default filename with timestamp
                timestamp = pd.Timestamp.now().strftime('%Y-%m-%d-%H-%M-%S')
                default_filename = f"voltage_drop_chart_{timestamp}.png"
                default_path = os.path.join(results_dir, default_filename)
                
                # Use QFileDialog
                dialog = QFileDialog()
                dialog.setFileMode(QFileDialog.AnyFile)
                dialog.setAcceptMode(QFileDialog.AcceptSave)
                dialog.setDefaultSuffix("png")
                dialog.setNameFilter("PNG files (*.png)")
                dialog.selectFile(default_path)
                
                if dialog.exec() == QFileDialog.Accepted:
                    filepath = dialog.selectedFiles()[0]
                    print(f"Selected filepath: {filepath}")  # Debug print
                else:
                    return False

            # Convert QUrl if needed
            if isinstance(filepath, QUrl):
                filepath = filepath.toLocalFile()
            elif filepath.startswith('file:///'):
                filepath = QUrl(filepath).toLocalFile()
            
            print(f"Final filepath for saving: {filepath}")  # Debug print
            self.grabRequested.emit(filepath, scale)
            return True
            
        except Exception as e:
            print(f"Error saving chart: {e}")
            return False

    @Slot(str)
    def exportTableData(self, filepath):
        """Save the cable size comparison table data to a CSV file."""
        try:
            # Show file dialog if filepath is empty or None
            if not filepath:
                from PySide6.QtWidgets import QFileDialog
                import os
                
                # Get absolute path to results directory
                results_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'results'))
                os.makedirs(results_dir, exist_ok=True)
                
                # Create default filename with timestamp
                timestamp = pd.Timestamp.now().strftime('%Y-%m-%d-%H-%M-%S')
                default_filename = f"cable_comparison_{timestamp}.csv"
                default_path = os.path.join(results_dir, default_filename)
                
                # Use QFileDialog with explicit default filename
                dialog = QFileDialog()
                dialog.setFileMode(QFileDialog.AnyFile)
                dialog.setAcceptMode(QFileDialog.AcceptSave)
                dialog.setDefaultSuffix("csv")
                dialog.setNameFilter("CSV files (*.csv)")
                dialog.selectFile(default_path)
                
                if dialog.exec() == QFileDialog.Accepted:
                    filepath = dialog.selectedFiles()[0]
                else:
                    self.tableExportStatusChanged.emit(False, "Export cancelled")
                    return False
            
            # Continue with existing code...
            if isinstance(filepath, QUrl):
                filepath = filepath.toLocalFile()
            elif filepath.startswith('file:///'):
                filepath = QUrl(filepath).toLocalFile()
            
            print(f"Saving cable comparison table to: {filepath}")
            
            # Ensure we have data to save
            if not hasattr(self, '_table_model') or self._table_model is None:
                self.tableExportStatusChanged.emit(False, "No table data to export")
                return False
                
            # Extract data from the table model
            rows = self._table_model._data
            if not rows:
                self.tableExportStatusChanged.emit(False, "Table contains no data to export")
                return False
                
            # Create DataFrame with column headers
            headers = ['Size (mm²)', 'Material', 'Cores', 'mV/A/m', 'Rating (A)', 
                       'Voltage Drop (V)', 'Drop (%)', 'Status']
            df = pd.DataFrame(rows, columns=headers)
            
            # Add metadata as header comments
            with open(filepath, 'w') as f:
                f.write(f"# Cable Size Comparison - {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"# System Voltage: {self._selected_voltage}\n")
                f.write(f"# Current: {self._current:.1f} A\n")
                f.write(f"# Length: {self._length:.1f} m\n")
                f.write(f"# Installation Method: {self._installation_method}\n")
                f.write(f"# Temperature: {self._temperature:.1f} °C\n")
                f.write(f"# Grouping Factor: {self._grouping_factor:.2f}\n")
                f.write(f"# ADMD Enabled: {'Yes' if self._admd_enabled else 'No'}\n")
                f.write(f"# Diversity Factor: {self._diversity_factor:.3f}\n\n")
            
            # Append the DataFrame to the file
            df.to_csv(filepath, mode='a', index=False)
            
            success_msg = f"Table data saved to {filepath}"
            print(success_msg)
            self.tableExportStatusChanged.emit(True, success_msg)
            return True
            
        except Exception as e:
            error_msg = f"Error exporting table data: {e}"
            print(error_msg)
            self.tableExportStatusChanged.emit(False, error_msg)
            return False

    @Slot(str)
    def exportTableToPDF(self, filepath):
        """Export cable comparison table to PDF format."""
        try:
            # Show file dialog if filepath is empty or None
            if not filepath:
                from PySide6.QtWidgets import QFileDialog
                import os
                
                # Get absolute path to results directory
                results_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'results'))
                os.makedirs(results_dir, exist_ok=True)
                
                # Create default filename with timestamp
                timestamp = pd.Timestamp.now().strftime('%Y-%m-%d-%H-%M-%S')
                default_filename = f"cable_comparison_{timestamp}.pdf"
                default_path = os.path.join(results_dir, default_filename)
                
                # Use QFileDialog with explicit default filename
                dialog = QFileDialog()
                dialog.setFileMode(QFileDialog.AnyFile)
                dialog.setAcceptMode(QFileDialog.AcceptSave)
                dialog.setDefaultSuffix("pdf")
                dialog.setNameFilter("PDF files (*.pdf)")
                dialog.selectFile(default_path)
                
                if dialog.exec() == QFileDialog.Accepted:
                    filepath = dialog.selectedFiles()[0]
                else:
                    self.tablePdfExportStatusChanged.emit(False, "Export cancelled")
                    return False
            
            # Convert QUrl if needed
            if isinstance(filepath, QUrl):
                filepath = filepath.toLocalFile()
            elif filepath.startswith('file:///'):
                filepath = QUrl(filepath).toLocalFile()
                
            print(f"Exporting table to PDF: {filepath}")
            
            # Ensure we have data to save
            if not hasattr(self, '_table_model') or self._table_model is None:
                self.tablePdfExportStatusChanged.emit(False, "No table data to export to PDF")
                return False
                
            # Extract data from the table model
            rows = self._table_model._data
            if not rows:
                self.tablePdfExportStatusChanged.emit(False, "Table contains no data to export to PDF")
                return False
            
            # Create PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=A4,
                rightMargin=36,  # Narrower margins for table
                leftMargin=36,
                topMargin=36,
                bottomMargin=36
            )
            
            # Get styles
            styles = getSampleStyleSheet()
            title_style = styles["Title"]
            heading_style = styles["Heading2"]
            normal_style = styles["Normal"]
            
            # Create contents
            elements = []
            
            # Add title
            elements.append(Paragraph("Cable Size Comparison", title_style))
            elements.append(Spacer(1, 0.25 * inch))
            
            # Add metadata
            metadata = [
                ["System Voltage:", self._selected_voltage],
                ["Current:", f"{self._current:.1f} A"],
                ["Length:", f"{self._length:.1f} m"],
                ["Installation Method:", self._installation_method],
                ["Temperature:", f"{self._temperature:.1f} °C"],
                ["Grouping Factor:", f"{self._grouping_factor:.2f}"],
                ["ADMD Enabled:", "Yes" if self._admd_enabled else "No"],
                ["Diversity Factor:", f"{self._diversity_factor:.3f}"]
            ]
            
            meta_table = Table(metadata, colWidths=[2*inch, 4*inch])
            meta_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]))
            elements.append(meta_table)
            elements.append(Spacer(1, 0.25 * inch))
            
            # Prepare table data with headers
            headers = ['Size (mm²)', 'Material', 'Cores', 'mV/A/m', 'Rating (A)', 
                      'V-Drop (V)', 'Drop (%)', 'Status']
            
            table_data = [headers]  # Start with headers
            
            # Format the data properly for the table
            for row in rows:
                formatted_row = []
                for i, item in enumerate(row):
                    if isinstance(item, float):
                        if i == 6:  # Drop percentage column
                            formatted_row.append(f"{item:.1f}%")
                        else:
                            formatted_row.append(f"{item:.1f}")
                    else:
                        formatted_row.append(str(item))
                table_data.append(formatted_row)
            
            # Create the table
            col_widths = [0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch, 0.8*inch]
            table = Table(table_data, colWidths=col_widths, repeatRows=1)
            
            # Apply table styles
            table_style = [
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.white),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]
            
            # Add special formatting for the status column
            for i in range(1, len(table_data)):
                status = table_data[i][7]  # Status column
                if status == "SEVERE":
                    table_style.append(('BACKGROUND', (7, i), (7, i), colors.mistyrose))
                    table_style.append(('TEXTCOLOR', (7, i), (7, i), colors.darkred))
                elif status == "WARNING":
                    table_style.append(('BACKGROUND', (7, i), (7, i), colors.linen))
                    table_style.append(('TEXTCOLOR', (7, i), (7, i), colors.darkorange))
                elif status == "SUBMAIN":
                    table_style.append(('BACKGROUND', (7, i), (7, i), colors.aliceblue))
                    table_style.append(('TEXTCOLOR', (7, i), (7, i), colors.blue))
                elif status == "OK":
                    table_style.append(('BACKGROUND', (7, i), (7, i), colors.mintcream))
                    table_style.append(('TEXTCOLOR', (7, i), (7, i), colors.darkgreen))
                
                # Alternate row colors for better readability
                if i % 2 == 0:
                    table_style.append(('BACKGROUND', (0, i), (6, i), colors.whitesmoke))
            
            table.setStyle(TableStyle(table_style))
            
            elements.append(table)
            
            # Add timestamp
            elements.append(Spacer(1, 0.5 * inch))
            timestamp = f"Generated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}"
            elements.append(Paragraph(timestamp, normal_style))
            
            # Build the PDF
            doc.build(elements)
            
            success_msg = f"Table exported to PDF: {filepath}"
            print(success_msg)
            self.tablePdfExportStatusChanged.emit(True, success_msg)
            return True
            
        except Exception as e:
            error_msg = f"Error exporting table to PDF: {e}"
            print(error_msg)
            self.tablePdfExportStatusChanged.emit(False, error_msg)
            return False

    @Slot(str, dict)
    def exportDetailsToPDF(self, filepath, details):
        """Export voltage drop calculation details to PDF format."""
        try:
            # Show file dialog if filepath is empty or None
            if not filepath:
                from PySide6.QtWidgets import QFileDialog
                import os
                
                # Get absolute path to results directory
                results_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'results'))
                os.makedirs(results_dir, exist_ok=True)
                
                # Create default filename with timestamp
                timestamp = pd.Timestamp.now().strftime('%Y-%m-%d-%H-%M-%S')
                default_filename = f"voltage_drop_details_{timestamp}.pdf"
                default_path = os.path.join(results_dir, default_filename)
                
                # Use QFileDialog with an explicit default filename
                dialog = QFileDialog()
                dialog.setFileMode(QFileDialog.AnyFile)
                dialog.setAcceptMode(QFileDialog.AcceptSave)
                dialog.setDefaultSuffix("pdf")
                dialog.setNameFilter("PDF files (*.pdf)")
                dialog.selectFile(default_path)
                
                if dialog.exec() == QFileDialog.Accepted:
                    filepath = dialog.selectedFiles()[0]
                else:
                    self.pdfExportStatusChanged.emit(False, "Export cancelled")
                    return False

            # Continue with existing code...
            if isinstance(filepath, QUrl):
                filepath = filepath.toLocalFile()
            elif filepath.startswith('file:///'):
                filepath = QUrl(filepath).toLocalFile()
                
            print(f"Exporting details to PDF: {filepath}")
            
            # Create PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            # Get styles
            styles = getSampleStyleSheet()
            title_style = styles["Title"]
            heading_style = styles["Heading2"]
            normal_style = styles["Normal"]
            
            # Create contents
            elements = []
            
            # Title
            elements.append(Paragraph("Voltage Drop Calculation Results", title_style))
            elements.append(Spacer(1, 0.25 * inch))
            
            # System configuration
            elements.append(Paragraph("System Configuration", heading_style))
            system_data = [
                ["Voltage System:", details.get("voltage_system", "")],
                ["ADMD Status:", "Enabled (1.5×)" if details.get("admd_enabled", False) else "Disabled"]
            ]
            system_table = Table(system_data, colWidths=[2*inch, 3*inch])
            system_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]))
            elements.append(system_table)
            elements.append(Spacer(1, 0.25 * inch))
            
            # Load details
            elements.append(Paragraph("Load Details", heading_style))
            load_data = [
                ["KVA per House:", f"{details.get('kva_per_house', 0):.1f} kVA"],
                ["Number of Houses:", str(details.get("num_houses", 1))],
                ["Diversity Factor:", f"{details.get('diversity_factor', 1.0):.3f}"],
                ["Total Load:", f"{details.get('total_kva', 0):.1f} kVA"],
                ["Current:", f"{details.get('current', 0):.1f} A"]
            ]
            load_table = Table(load_data, colWidths=[2*inch, 3*inch])
            load_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]))
            elements.append(load_table)
            elements.append(Spacer(1, 0.25 * inch))
            
            # Cable details
            elements.append(Paragraph("Cable Details", heading_style))
            cable_data = [
                ["Cable Size:", f"{details.get('cable_size', '')} mm²"],
                ["Material:", details.get("conductor_material", "")],
                ["Configuration:", details.get("core_type", "")],
                ["Length:", f"{details.get('length', 0)} m"],
                ["Installation:", details.get("installation_method", "")],
                ["Temperature:", f"{details.get('temperature', 25)} °C"],
                ["Grouping Factor:", details.get("grouping_factor", "1.0")]
            ]
            cable_table = Table(cable_data, colWidths=[2*inch, 3*inch])
            cable_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
            ]))
            elements.append(cable_table)
            elements.append(Spacer(1, 0.25 * inch))
            
            # Results
            elements.append(Paragraph("Results", heading_style))
            
            # Handle special coloring for voltage drop results
            voltage_drop = details.get("voltage_drop", 0)
            drop_percent = details.get("drop_percent", 0)
            drop_color = colors.red if drop_percent > 5 else colors.green
            
            results_data = [
                ["Network Fuse / Rating:", details.get("combined_rating_info", "N/A")],
                ["Voltage Drop:", f"{voltage_drop:.2f} V"],
                ["Drop Percentage:", f"{drop_percent:.2f}%"]
            ]
            results_table = Table(results_data, colWidths=[2*inch, 3*inch])
            results_table.setStyle(TableStyle([
                ('GRID', (0, 0), (-1, -1), 1, colors.lightgrey),
                ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 6),
                ('TEXTCOLOR', (1, 1), (1, 2), drop_color),  # Color the voltage drop and percentage
            ]))
            elements.append(results_table)
            
            # Add timestamp
            elements.append(Spacer(1, 0.5 * inch))
            timestamp = f"Generated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}"
            elements.append(Paragraph(timestamp, normal_style))
            
            # Build the PDF
            doc.build(elements)
            
            success_msg = f"Details exported to PDF: {filepath}"
            print(success_msg)
            self.pdfExportStatusChanged.emit(True, success_msg)
            return True
            
        except Exception as e:
            error_msg = f"Error exporting details to PDF: {e}"
            print(error_msg)
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False

    def _calculate_voltage_drop(self):
        """Calculate voltage drop using mV/A/m method."""
        try:
            if self._current <= 0 or self._length <= 0:
                return

            # Apply ADMD factor if enabled and using 415V
            admd_multiplier = self._admd_factor if (self._admd_enabled and self._voltage > 230) else 1.0
            # print(f"ADMD multiplier: {admd_multiplier}, enabled: {self._admd_enabled}, voltage: {self._voltage}")

            table_data = []
            for _, cable in self._cable_data.iterrows():
                mv_per_am = float(cable['mv_per_am'])
                
                # Calculate voltage drop
                v_drop = (
                    self._current * 
                    self._length * 
                    mv_per_am * 
                    self._get_temperature_factor() * 
                    self._get_installation_factor() * 
                    self._grouping_factor * 
                    admd_multiplier /  # Apply ADMD factor
                    1000.0
                )
                
                drop_percent = (v_drop / self._voltage) * 100  # Calculate percentage
                
                # Determine status based on AS/NZS 3008.1.1
                status = "OK"
                if drop_percent > 7.0:
                    status = "SEVERE"
                elif drop_percent > 5.0:
                    status = "WARNING"
                elif drop_percent > 2.0:
                    status = "SUBMAIN"
                
                table_data.append([
                    float(cable['size']),
                    self._conductor_material,
                    self._core_type,
                    mv_per_am,
                    cable['max_current'],
                    v_drop,
                    drop_percent,
                    status
                ])
            
            self._table_model.update_data(table_data)
            self.tableDataChanged.emit()
            
            # Update single cable calculation if selected
            if self._selected_cable is not None:
                self._voltage_drop = (
                    self._current * 
                    self._length * 
                    float(self._selected_cable['mv_per_am']) * 
                    self._get_temperature_factor() * 
                    self._get_installation_factor() * 
                    self._grouping_factor *
                    admd_multiplier /
                    1000.0
                )
                self.voltageDropCalculated.emit(self._voltage_drop)
                
                # Always update fuse size after a calculation
                self._update_fuse_size()
            
        except Exception as e:
            print(f"Error calculating voltage drops: {e}")

    def _get_temperature_factor(self):
        """Get temperature correction factor."""
        base_temp = 75  # °C
        return 1 + 0.004 * (self._temperature - base_temp)
    
    def _get_installation_factor(self):
        """Get installation method factor with material consideration."""
        base_factors = {
            "A1 - Enclosed in thermal insulation": 1.25,
            "A2 - Enclosed in wall/ceiling": 1.15,
            "B1 - Enclosed in conduit in wall": 1.1,
            "B2 - Enclosed in trunking/conduit": 1.1,
            "C - Clipped direct": 1.0,
            "D1 - Underground direct buried": 1.1,
            "D2 - Underground in conduit": 1.15,
            "E - Free air": 0.95,
            "F - Cable tray/ladder/cleated": 0.95,
            "G - Spaced from surface": 0.90
        }
        
        factor = base_factors.get(self._installation_method, 1.0)
        
        # Apply material-specific adjustments
        if self._conductor_material == "Al":
            factor *= 1.6  # Aluminum has higher resistance

        # Apply core configuration adjustments
        if self._core_type == "3C+E":
            factor *= 1.05  # Three-core cables have slightly higher impedance
            
        return factor
    
    @Property(float, notify=voltageDropCalculated)
    def voltageDrop(self):
        """Get calculated voltage drop in volts."""
        return self._voltage_drop
    
    @Property('QVariantList', notify=cablesChanged)  # Change return type and add notify
    def availableCables(self):
        """Get list of available cable sizes."""
        return self._available_cables
    
    @Property('QVariantList', notify=methodsChanged)  # Change return type and add notify
    def installationMethods(self):
        """Get list of available installation methods."""
        return self._installation_methods

    @Property('QVariantList', notify=conductorChanged)
    def conductorTypes(self):
        return self._conductor_types

    @Property('QVariantList', notify=coreTypeChanged)
    def coreConfigurations(self):
        return self._core_configurations

    @Property(str, notify=conductorChanged)
    def conductorMaterial(self):
        return self._conductor_material

    @Property(str, notify=coreTypeChanged)
    def coreType(self):
        return self._core_type

    @Property(QObject, notify=tableDataChanged)
    def tableModel(self):
        return self._table_model

    @Property(str, notify=fuseSizeChanged)
    def networkFuseSize(self):
        """Get current network fuse size."""
        return self._current_fuse_size
        
    @Property(float, notify=conductorRatingChanged)
    def conductorRating(self):
        """Get current conductor rating in amperes."""
        return self._conductor_rating
        
    @Property(str, notify=combinedRatingChanged)
    def combinedRatingInfo(self):
        """Get combined fuse size and conductor rating information."""
        return self._combined_rating_info

    @Slot(str)
    def exportChartDataCSV(self, data_json):
        """Export chart data as CSV."""
        try:
            data = json.loads(data_json)
            filepath = None  # Initialize filepath variable
            
            # Show file dialog
            from PySide6.QtWidgets import QFileDialog
            import os
            
            results_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'results'))
            os.makedirs(results_dir, exist_ok=True)
            
            timestamp = pd.Timestamp.now().strftime('%Y-%m-%d-%H-%M-%S')
            default_filename = f"voltage_drop_chart_{timestamp}.csv"
            default_path = os.path.join(results_dir, default_filename)
            
            dialog = QFileDialog()
            dialog.setFileMode(QFileDialog.AnyFile)
            dialog.setAcceptMode(QFileDialog.AcceptSave)
            dialog.setDefaultSuffix("csv")
            dialog.setNameFilter("CSV files (*.csv)")
            dialog.selectFile(default_path)
            
            if dialog.exec() == QFileDialog.Accepted:
                filepath = dialog.selectedFiles()[0]
            else:
                self.tableExportStatusChanged.emit(False, "Export cancelled")
                return False

            # Continue only if we have a filepath
            if filepath:
                # Convert QUrl if needed
                if isinstance(filepath, QUrl):
                    filepath = filepath.toLocalFile()
                elif filepath.startswith('file:///'):
                    filepath = QUrl(filepath).toLocalFile()

                # Create DataFrame and save
                rows = []
                rows.append({
                    'cable_size': data['currentPoint']['cableSize'],
                    'drop_percentage': data['currentPoint']['dropPercentage'],
                    'current': data['currentPoint']['current'],
                    'type': 'current'
                })
                
                for point in data['comparisonPoints']:
                    rows.append({
                        'cable_size': point['cableSize'],
                        'drop_percentage': point['dropPercent'],
                        'status': point['status'],
                        'type': 'comparison'
                    })
                    
                df = pd.DataFrame(rows)
                df.to_csv(filepath, index=False)
                self.tableExportStatusChanged.emit(True, f"Chart data exported to {filepath}")
                return True
            
        except Exception as e:
            self.tableExportStatusChanged.emit(False, f"Error exporting chart data: {e}")
            return False

    @Slot(str)
    def exportChartDataJSON(self, data_json):
        """Export chart data as JSON."""
        try:
            data = json.loads(data_json)
            
            # Show file dialog if filepath is empty or None
            from PySide6.QtWidgets import QFileDialog
            import os
            
            # Get absolute path to results directory
            results_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'results'))
            os.makedirs(results_dir, exist_ok=True)
            
            # Create default filename with timestamp
            timestamp = pd.Timestamp.now().strftime('%Y-%m-%d-%H-%M-%S')
            default_filename = f"voltage_drop_chart_{timestamp}.json"
            default_path = os.path.join(results_dir, default_filename)
            
            dialog = QFileDialog()
            dialog.setFileMode(QFileDialog.AnyFile)
            dialog.setAcceptMode(QFileDialog.AcceptSave)
            dialog.setDefaultSuffix("json")
            dialog.setNameFilter("JSON files (*.json)")
            dialog.selectFile(default_path)
            
            if dialog.exec() == QFileDialog.Accepted:
                filepath = dialog.selectedFiles()[0]
                
                # Convert QUrl if needed
                if isinstance(filepath, QUrl):
                    filepath = filepath.toLocalFile()
                elif filepath.startswith('file:///'):
                    filepath = QUrl(filepath).toLocalFile()
                
                # Save the data
                with open(filepath, 'w') as f:
                    json.dump(data, f, indent=2)
                
                success_msg = f"Chart data exported to {filepath}"
                print(success_msg)
                self.tableExportStatusChanged.emit(True, success_msg)
                return True
            else:
                self.tableExportStatusChanged.emit(False, "Export cancelled")
                return False
            
        except Exception as e:
            error_msg = f"Error exporting chart data: {e}"
            print(error_msg)
            self.tableExportStatusChanged.emit(False, error_msg)
            return False
