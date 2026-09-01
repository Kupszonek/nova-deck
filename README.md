<p align="center">
  <img src="https://github.com/user-attachments/assets/e7f3e857-77cf-4c6b-ac05-cfcff2d39c16" width="520" alt="NOVA Deck logo"/>
</p>

<h1 align="center">NOVA Deck</h1>

<p align="center">
  DIY 15-key macro deck powered by ESP32 and a custom Windows desktop application.
</p>

NOVA Deck is a DIY Stream Deck-style macro pad with **15 mechanical keys**, an ESP32 controller and a custom Windows desktop application built with Godot.

It allows you to launch applications, execute keyboard shortcuts and configure up to **60 actions across 4 pages**.

> 🚧 **NOVA Deck is currently in development.**

---

## Preview

### NOVA Deck

<!-- Add a photo or render of the finished NOVA Deck here -->

<p align="center">

</p>

### Desktop Application

<p align="center">
  <img src="https://github.com/user-attachments/assets/974e18e4-60b5-4f2e-9cdd-bc02a9d42f02" width="800" alt="NOVA Deck desktop application"/>
</p>

---

## Features

- 15 mechanical MX-style buttons
- 4 pages / 60 configurable actions
- Launch `.exe` applications
- Launch Windows `.lnk` shortcuts
- Keyboard shortcut support
- Manual shortcut builder
- Drag & drop application configuration
- Automatic application icon extraction
- System tray support
- Custom desktop UI
- Polish and English language support
- Local configuration storage

---

## Hardware

NOVA Deck uses a **3 × 5 switch matrix** with 15 MX-compatible mechanical switches and diodes.

### Components

- 1× ESP32-S3
- 15× MX-compatible mechanical switches
- 15× 1N4148 diodes
- 15× MX-compatible keycaps
- USB cable
- Wires
- 3D-printed enclosure
- Mounting hardware

An **ESP32-C3 Super Mini mounting option** is also available, but this version is currently untested.

### ESP32-S3 Pinout

| Function | GPIO |
|---|---:|
| Row 1 | 4 |
| Row 2 | 5 |
| Row 3 | 6 |
| Column 1 | 13 |
| Column 2 | 12 |
| Column 3 | 11 |
| Column 4 | 10 |
| Column 5 | 9 |
| Onboard RGB LED | 48 |

---

## Wiring Diagram

<p align="center">
  <img src="https://github.com/user-attachments/assets/f33572a2-46b0-42bc-b3a2-760409ad30f7" width="1000" alt="NOVA Deck wiring diagram"/>
</p>

> **The wiring diagram is shown from the solder side (rear view).**  
> The column order is mirrored compared with the front/keycap side.

Each switch uses its own **1N4148 diode**.

The ESP32 uses its internal pull-up resistors for the matrix rows, so no additional pull-up resistors are required.

---

## ESP32-C3 Super Mini

The NOVA Deck enclosure also includes a mounting option for the **ESP32-C3 Super Mini**.

The ESP32-S3 is currently the main development and tested controller.

> ⚠️ The ESP32-C3 version is currently **untested**.  
> Pinout and firmware information for this version will be added separately.

---

## Keycaps

NOVA Deck uses standard **MX-compatible keycaps**.

Custom keycaps with icons can be generated and 3D printed using this community-made MakerWorld model:

**[Custom Keycap Generator on MakerWorld](https://makerworld.com/en/models/2959969-custom-keycap-generator?from=search#profileId-3317786)**

For my NOVA Deck build, I use the **low-profile keycap version** generated using this model.

This makes it possible to create custom keycaps for applications, shortcuts, games and other actions.

Regular MX-compatible keycaps can also be used.

> The keycap generator linked above was created by another MakerWorld user and is not part of the NOVA Deck project.

---

## 3D Model

The NOVA Deck enclosure will be available on **MakerWorld**.

**[Download NOVA Deck on MakerWorld](PASTE_NOVA_DECK_MAKERWORLD_LINK_HERE)**

Available controller mounting options:

- ESP32-S3
- ESP32-C3 Super Mini

The MakerWorld page will contain:

- printable model files
- recommended print settings
- assembly information
- controller mounting variants

---

## Desktop Application

The NOVA Deck desktop application is built with:

- Godot
- GDScript
- GdSerial

Currently supported platform:

**Windows**

> ⚠️ **The NOVA Deck desktop application must be running for the physical deck to work.**

The ESP32 sends button presses to the desktop application over USB serial.

The desktop application then executes the action assigned to the pressed button.

The application can remain minimized in the **Windows system tray** while NOVA Deck is being used.

### Controls

- **Single click** on a virtual button — open its configuration
- **Double click** — execute its assigned action
- **Physical button press** — execute the assigned action

Applications can also be configured by dragging an `.exe` or `.lnk` file directly onto a virtual NOVA Deck button.

---

## Firmware

The ESP32 firmware uses the Arduino framework.

It handles:

- 3 × 5 matrix scanning
- software debouncing
- USB serial communication
- button press events
- NOVA Deck device identification

Serial communication runs at:

```text
115200 baud
```

A physical button press is sent in the following format:

```text
BUTTON:1
BUTTON:2
...
BUTTON:15
```

The desktop application can identify the connected NOVA Deck using a simple serial handshake.

The application sends:

```text
PING
```

The ESP32 responds with:

```text
NOVA_DECK:PONG
```

### Required Arduino Library

- Adafruit NeoPixel

---

## Installation

### 1. Flash the ESP32

1. Install Arduino IDE.
2. Install ESP32 board support.
3. Install the **Adafruit NeoPixel** library.
4. Open the NOVA Deck firmware.
5. Select the correct ESP32 board.
6. Select the correct COM port.
7. Upload the firmware.

### 2. Install NOVA Deck

1. Download the latest NOVA Deck installer from **GitHub Releases**.
2. Install NOVA Deck.
3. Connect the ESP32 using USB.
4. Launch the NOVA Deck application.
5. Configure your buttons.

The application can remain minimized in the system tray while the deck is in use.

> Closing the application completely will stop the physical NOVA Deck buttons from executing actions.

---

## Usage

### Assign an Application

Click a virtual button and select an application using the configuration panel.

You can also simply:

1. Drag an `.exe` or `.lnk` file.
2. Drop it onto a NOVA Deck button.

The application name and icon will be detected automatically when possible.

Configuration is saved automatically.

### Execute an Action

Press the corresponding physical switch.

```text
Physical Button
      ↓
    ESP32
      ↓
 USB Serial
      ↓
NOVA Deck App
      ↓
Configured Action
```

---

## Roadmap

- [x] 15-button matrix
- [x] 4 configurable pages
- [x] Application launching
- [x] Windows shortcut launching
- [x] Keyboard shortcuts
- [x] Manual shortcut builder
- [x] Drag & drop configuration
- [x] Automatic application icon extraction
- [x] System tray
- [x] Polish / English UI
- [x] ESP32-S3 enclosure mount
- [x] ESP32-C3 Super Mini enclosure mount
- [x] Wiring diagram
- [ ] Final assembly guide
- [ ] ESP32-C3 testing and firmware documentation
- [ ] Additional action types
- [ ] More customization options

---

## Credits

NOVA Deck uses third-party software and libraries including:

- Godot Engine
- GdSerial
- Adafruit NeoPixel

The custom keycap generator recommended above is a separate community project and is not created or maintained by the NOVA Deck project.

All third-party software, libraries, assets and models remain subject to their respective licenses.

---

## License

### Software & Firmware

**Copyright © 2026 Kupszonek. All rights reserved.**

The NOVA Deck desktop application, firmware, source code, branding and documentation are owned and maintained by the NOVA Deck author.

The official NOVA Deck software and firmware may be used for personal, non-commercial use.

Without prior permission, you may not:

- redistribute the NOVA Deck source code or compiled software
- publish modified or derivative versions
- repackage the software under another name
- sell, sublicense or commercially distribute the software
- distribute unofficial builds using the NOVA Deck name, logo or branding

See [`LICENSE`](LICENSE) for the full software license.

### 3D Models

Original NOVA Deck enclosure and 3D models are licensed under:

**CC BY-NC-ND 4.0 — Attribution-NonCommercial-NoDerivatives**

You may download and print the original models for personal, non-commercial use.

You may not:

- sell the NOVA Deck models or printed versions commercially
- redistribute modified or remixed versions
- use the models as part of a commercial product

Third-party models and assets, including the keycap generator linked above, remain subject to their respective licenses.
