# from PySide6.QtCore import Slot, Signal, Property, QObject
from PySide6.QtCore import *
from PySide6.QtCharts import *
from PySide6.QtQuick import QQuickPaintedItem
from PySide6.QtGui import QPainter, QPen, QColor

import numpy as np
import math
import electricpy as ep
from electricpy import conversions
from electricpy.visu import SeriesRLC
from electricpy.visu import phasorplot

class SeriesRLCChart(QObject):
    chartDataChanged = Signal()
    resonantFreqChanged = Signal(float)
    axisRangeChanged = Signal()  # Add new signal
    formattedDataChanged = Signal(list)  # Add new signal

    def __init__(self):
        super().__init__()
        # Set default values for 50Hz resonance:
        # f = 1/(2π√(LC))
        # For 50Hz with L = 0.1H, we need C = 1/(4π²f²L) ≈ 101.3µF
        self._resistance = 10.0     # 10 Ω for a clear peak
        self._inductance = 0.1      # 0.1 H (henries)
        self._capacitance = 101.3e-6  # 101.3 µF - will resonate at 50 Hz
        self._frequency_range = (0, 100)  # Adjust range to better show 50Hz
        self._chart_data = []
        self._resonant_freq = 0.0
        self._axis_x_min = 0
        self._axis_x_max = 100
        self._axis_y_min = 0
        self._axis_y_max = 1
        self._formatted_points = []
        self.generateChartData()

    @Slot(float)
    def setResistance(self, resistance):
        self._resistance = resistance
        self.generateChartData()

    @Slot(float)
    def setInductance(self, inductance):
        self._inductance = inductance
        self.generateChartData()

    @Slot(float)
    def setCapacitance(self, capacitance):
        self._capacitance = capacitance
        self.generateChartData()

    @Slot(float, float)
    def setFrequencyRange(self, start, end):
        """Set frequency range with separate start and end values"""
        if start >= 0 and end > start:
            self._frequency_range = (float(start), float(end))
            self.generateChartData()

    @Property(float, notify=axisRangeChanged)
    def axisXMin(self):
        return self._axis_x_min

    @Property(float, notify=axisRangeChanged)
    def axisXMax(self):
        return self._axis_x_max

    @Property(float, notify=axisRangeChanged)
    def axisYMin(self):
        return self._axis_y_min

    @Property(float, notify=axisRangeChanged)
    def axisYMax(self):
        return self._axis_y_max

    def updateAxisRanges(self):
        """Update axis ranges based on data and resonant frequency"""
        if self._chart_data:
            max_y = max(point[1] for point in self._chart_data)
            self._axis_y_max = max_y * 1.1
            self._axis_y_min = 0
            
            # Center around resonant frequency
            self._axis_x_min = max(0, self._resonant_freq * 0.5)
            self._axis_x_max = self._resonant_freq * 1.5
            
            self.axisRangeChanged.emit()

    @Slot(QXYSeries)
    def fill_series(self, series):
        """Fill series with points using QPointF and replace"""
        points = []
        for point in self._formatted_points:
            points.append(QPointF(point['x'], point['y']))
        series.replace(points)

    def generateChartData(self):
        if self._resistance > 0 and self._inductance > 0 and self._capacitance > 0:
            try:
                # Calculate resonant frequency
                self._resonant_freq = 1.0 / (2.0 * np.pi * np.sqrt(self._inductance * self._capacitance))
                self.resonantFreqChanged.emit(self._resonant_freq)

                # Create frequency points with extra density around resonance
                f_start = max(1, self._frequency_range[0])
                f_end = self._frequency_range[1]
                
                # Create three ranges of points: before, around, and after resonance
                f1 = np.linspace(f_start, self._resonant_freq * 0.9, 200)
                f2 = np.linspace(self._resonant_freq * 0.9, self._resonant_freq * 1.1, 600)
                f3 = np.linspace(self._resonant_freq * 1.1, f_end, 200)
                
                frequencies = np.concatenate([f1, f2, f3])
                omega = 2 * np.pi * frequencies
                
                # Calculate impedance components and gain
                z_r = np.full_like(omega, self._resistance)
                z_l = omega * self._inductance
                z_c = 1 / (omega * self._capacitance)
                z_total = np.sqrt(z_r**2 + (z_l - z_c)**2)
                gain = 1 / z_total
                
                # Create data points
                valid_points = []
                for f, g in zip(frequencies, gain):
                    if not (np.isnan(g) or np.isinf(g)):
                        valid_points.append([float(f), float(g)])

                if valid_points:
                    self._chart_data = valid_points
                    self._formatted_points = [{"x": p[0], "y": p[1]} for p in valid_points]
                    max_gain = max(p[1] for p in valid_points)
                    
                    # Create resonant line points
                    self._resonant_line = [
                        {"x": float(self._resonant_freq), "y": float(0)},
                        {"x": float(self._resonant_freq), "y": float(max_gain * 1.2)}
                    ]
                    
                    self.updateAxisRanges()
                    self.formattedDataChanged.emit([self._formatted_points, self._resonant_line])
                    self.chartDataChanged.emit()
                    
            except Exception as e:
                print(f"Error generating chart data: {e}")

    @Slot(float)  # Change to accept single argument
    def zoomX(self, factor):
        """Zoom X axis by factor"""
        center = (self._axis_x_min + self._axis_x_max) / 2
        current_range = self._axis_x_max - self._axis_x_min
        new_range = current_range * factor
        self._axis_x_min = center - new_range / 2
        self._axis_x_max = center + new_range / 2
        self.axisRangeChanged.emit()

    @Slot(float)
    def panX(self, factor):
        """Pan X axis by factor of current range"""
        current_range = self._axis_x_max - self._axis_x_min
        delta = current_range * factor
        self._axis_x_min += delta
        self._axis_x_max += delta
        self.axisRangeChanged.emit()

    @Slot()
    def resetZoom(self):
        """Reset to default zoom level"""
        self._axis_x_min = self._frequency_range[0]
        self._axis_x_max = self._frequency_range[1]
        self.updateAxisRanges()

    @Property(list, notify=chartDataChanged)
    def chartData(self):
        return self._chart_data

    @Property(float, notify=resonantFreqChanged)
    def resonantFreq(self):
        return self._resonant_freq