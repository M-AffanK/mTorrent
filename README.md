# mTorrent
Flutter mobile client for the mTorrent distributed file sharing system. Connects to a coordinator server over TCP and supports uploading, downloading, and browsing shared files.

## Overview
This is the mobile-facing component of a hybrid distributed file sharing system. It communicates with a Coordinator Server over raw TCP sockets using a custom text-based protocol. The client is responsible for splitting files into chunks during upload and reassembling them during download.

## Features
- Connect to configurable server host/port
- List all files
- Search files by name substring
- Upload a picked file (chunked upload)
- Download by file ID
- Download by share token/URL
- Reconstruct and save file in app documents directory

## Requirements

- Flutter SDK ≥ 3.0.0
- A running mTorrent coordinator server

## Getting Started

### Installation

```bash
git clone https://github.com/M-AffanK/mTorrent.git
cd mTorrent
flutter pub get
```

### Running the App

```bash
flutter run
```

After launching the app, enter the coordinator's host and port and tap **OK**.

## Usage

| Action | How |
|---|---|
| List all files | Tap **Refresh button** |
| Search by name | Type in search box, tap **Search** |
| Upload a file | Tap **Upload**, pick from device |
| Download through List | Tap ⬇ icon on any listed file |
| Download via Share | Paste `mtorrent://share/...` URL, tap **Download** |

Downloaded files are saved to the mobile's Download directory.
