import logging
from typing import Any
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from .interfaces import ILogger, IQmlEngine, IModelFactory
from models.ThreePhase import ThreePhaseSineWaveModel
from models.ElectricPy import SeriesRLCChart
from models.VoltageDrop import VoltageDrop
from models.Calculator import ConversionCalculator, ResonantFrequencyCalculator, SineCalculator
from models.ResultsManager import ResultsManager
from models.RealTimeChart import RealTimeChart

class DefaultLogger(ILogger):
    """Default logging implementation using Python's logging module."""
    
    def setup(self, level: str) -> None:
        """Configure the logging system.
        
        Args:
            level: Logging level to use
        """
        logging.basicConfig(level=level)

class QmlEngineWrapper(IQmlEngine):
    """Wrapper for QQmlApplicationEngine providing initialization control."""
    
    def __init__(self, app=None):
        self.app = app
        self.engine = None
        
    def initialize(self, app):
        """Initialize the QML engine with a QApplication instance.
        
        Args:
            app: QApplication instance
        """
        self.app = app
        self.engine = QQmlApplicationEngine()
        
    def load_qml(self, path: str) -> None:
        """Load QML file at specified path.
        
        Args:
            path: Path to QML file
            
        Raises:
            RuntimeError: If engine not initialized
        """
        if not self.engine:
            raise RuntimeError("QML Engine not initialized. Call initialize() first")
        self.engine.load(path)
        
    def register_type(self, type_class: type, uri: str, major: int, minor: int, name: str) -> None:
        qmlRegisterType(type_class, uri, major, minor, name)

class ModelFactory(IModelFactory):
    """Factory for creating model instances.
    
    Manages creation of various model types with support for
    configuration parameters.
    """
    
    def create_model(self, model_type: str, **kwargs) -> Any:
        """Create a model instance of specified type.
        
        Args:
            model_type: Type of model to create
            **kwargs: Configuration parameters for model
            
        Returns:
            Created model instance
            
        Raises:
            ValueError: If model_type is unknown
        """
        model_map = {
            "three_phase": ThreePhaseSineWaveModel,
            "resonant_freq": ResonantFrequencyCalculator,
            "conversion_calc": ConversionCalculator,
            "series_rlc_chart": SeriesRLCChart,
            "voltage_drop": VoltageDrop,
            "results_manager": ResultsManager,
            "sine_calc": SineCalculator,
            "realtime_chart": RealTimeChart
        }
        
        if model_type not in model_map:
            raise ValueError(f"Unknown model type: {model_type}")
            
        creator = model_map[model_type]
        return creator()
