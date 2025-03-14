# Electrical Calculator

A comprehensive electrical engineering calculator suite built with Python and QML.

## Features
![Image](https://github.com/user-attachments/assets/344f6725-d1f3-4d2c-80be-b3ae8c69b64b)

![Image](https://github.com/user-attachments/assets/f14193c9-bb32-4ed7-8e2a-3737d09fbb80)

![Image](https://github.com/user-attachments/assets/d112afaf-e464-4e35-87f1-8dae126792d3)

![Image](https://github.com/user-attachments/assets/78289c45-4dae-4b97-8e61-c341a3de903c)

![Image](https://github.com/user-attachments/assets/1b5119a5-dc3e-4ed3-9f72-887c32b9437d)

![Image](https://github.com/user-attachments/assets/c29e6749-ead1-4cb7-8332-aab87a47f8ed)

![Image](https://github.com/user-attachments/assets/efc13b3c-2bcd-450a-bfed-cbdf3d733740)

![Image](https://github.com/user-attachments/assets/c1909aba-47fa-4016-aead-fc55083e2c73)

![Image](https://github.com/user-attachments/assets/dd3c6ca1-404a-4111-8db9-d93a5e479611)

# Installation

```
pip install -r requirements.txt
pip install git+https://github.com/engineerjoe440/ElectricPy.git
```

```
pyside6-rcc resources.qrc -o data/rc_resources.py
```

## Building for Windows

1. Install build requirements:
```bash
pip install -r build_requirements.txt
```

2. Run the build script:
```bash
python build_scripts/windows_build.py
```

3. Create installer (requires NSIS):
- Install NSIS from https://nsis.sourceforge.io/
- Right-click installer/windows_installer.nsi and select "Compile NSIS Script"

The executable will be in the `dist` folder, and the installer will be created as `ElectricalCalculator_Setup.exe`.

### Build Requirements
- Python 3.8 or later
- PyInstaller
- PySide6
- NSIS (for creating installer)

## Cross-Platform Building

### Building Windows Executable from Linux
1. Install Wine:
```bash
sudo apt install wine64
```

2. Run cross-platform build script:
```bash
python build_scripts/cross_build.py
```

The script will automatically:
- Download Python 3.8.10 for Windows
- Set up Wine environment
- Install Python in Wine
- Install dependencies in Wine Python
- Build the Windows executable

```bash
pip install -r build_requirements.txt
python build_scripts/windows_build.py
```