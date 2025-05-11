# WebTorrent Rust WebAssembly Wrapper

This project is a WebAssembly (WASM) wrapper for WebTorrent implemented in Rust. It allows you to create a browser-based file sharing application using WebTorrent functionality, with the core logic written in Rust.

## Features

- Share files via WebTorrent using a magnet URI
- Download files from peers via WebTorrent in the browser
- Displays file progress and peers count during downloads

## Prerequisites

- Rust installed on your system (Make sure to install Rust via `rustup` if you haven't already)
- `wasm-pack` installed (Install it via `cargo install wasm-pack`)
- Python installed for serving the HTML page

## Setup

### 1. Clone the Repository

Clone the repository to your local machine:

```
git clone https://github.com/anchalshivank/webtorrent-rs-wrapper.git
cd webtorrent-rs-wrapper
```

### 2. Install Dependencies

Install the necessary dependencies:

```
cargo install wasm-pack
```

### 3. Build the Project

Run the following commands to build the WebAssembly binary:

```
# Clean any previous builds
cargo clean

# Build the project for the WebAssembly target (web)
wasm-pack build --target web
```

### 4. Serve the Application

To view the application, you need to serve the generated `index.html` in a local server. You can use Python's built-in HTTP server:

```bash
python3 -m http.server 8080
```

### 5. Open in a Browser

Once the server is running, open your browser and go to `http://localhost:8080`. The application will allow you to upload and share files, or download files from other peers.

## Build Script (Optional)

If you have a `build.sh` script for automating the build process, make sure to grant it execute permissions by running:

```
chmod +x ./build.sh
```

You can then execute the script with the following:

```
./build.sh
```

This will run the necessary build steps for the project.

## Project Structure

* `src/`: Contains the Rust source code for the WebTorrent wrapper
* `pkg/`: Contains the generated WebAssembly package
* `index.html`: The HTML file for the browser-based file-sharing app

## Troubleshooting

* Ensure you have all the necessary dependencies installed, including `wasm-pack`, Rust, and Python.
* If you encounter issues related to missing files (e.g., `package.json`), make sure the required files are present in the directory.

## Contributing

Feel free to contribute by opening issues or pull requests. Contributions are welcome!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
