// This shim connects the WebTorrent JS library with our Rust WASM wrapper

// WebTorrent client class that wraps the JS library
export class WebTorrentClient {
  constructor() {
    // Require the WebTorrent library (should be loaded on the page)
    if (typeof WebTorrent === 'undefined') {
      throw new Error('WebTorrent library not found. Make sure to include the WebTorrent script in your HTML.');
    }
    
    this.client = new WebTorrent();
    console.log('WebTorrent client created:', this.client.version);
  }

  // Create a torrent and start seeding
  seed(input, opts, onseed) {
    return new Promise((resolve, reject) => {
      this.client.seed(input, opts, torrent => {
        resolve({
          info_hash: torrent.infoHash,
          magnet_uri: torrent.magnetURI,
          name: torrent.name,
          files: torrent.files.map(f => ({ 
            name: f.name, 
            path: f.path,
            length: f.length 
          }))
        });
      });
    });
  }

  // Add a torrent and start downloading
  add(torrentId, opts, ontorrent) {
    return new Promise((resolve, reject) => {
      try {
        const torrent = this.client.add(torrentId, opts, torrent => {
          // This callback runs when metadata is available
          console.log('Got torrent metadata:', torrent.name);
        });

        // Create a wrapper for the torrent with required methods
        const torrentWrapper = {
          infoHash: torrent.infoHash,
          magnetURI: torrent.magnetURI,
          name: torrent.name,
          
          // Add event listener method
          on: (event, callback) => {
            torrent.on(event, (...args) => {
              callback(...args);
            });
          },
          
          // Get progress (0-1)
          progress: () => torrent.progress,
          
          // Get peers info
          peers: () => torrent.wires.map(wire => ({
            downloaded: wire.downloaded,
            uploaded: wire.uploaded,
            downloadSpeed: wire.downloadSpeed(),
            uploadSpeed: wire.uploadSpeed()
          })),
          
          // Get files
          files: () => torrent.files.map(file => ({
            name: () => file.name,
            path: () => file.path,
            length: () => file.length,
            get_blob: () => {
              return new Promise((resolve) => {
                file.getBlob((err, blob) => {
                  if (err) console.error(err);
                  resolve(blob);
                });
              });
            }
          }))
        };
        
        resolve(torrentWrapper);
      } catch (err) {
        reject(err.message);
      }
    });
  }

  // Create a server to stream torrent content
  createServer(options, force) {
    const server = this.client.createServer(options);
    return {
      url: `http://localhost:${server.address().port}`
    };
  }

  // Get torrent by ID
  getTorrent(torrentId) {
    return Promise.resolve(this.client.get(torrentId));
  }

  // Remove a torrent
  remove(torrentId, opts, cb) {
    this.client.remove(torrentId, opts);
  }

  // Limit download speed (bytes/sec)
  throttleDownload(rate) {
    this.client.throttleDownload(rate);
  }

  // Limit upload speed (bytes/sec)
  throttleUpload(rate) {
    this.client.throttleUpload(rate);
  }

  // Destroy client and stop all torrents
  destroy(cb) {
    this.client.destroy();
  }

  // Helper methods
  isReadable(obj) {
    return (
      obj instanceof Blob || 
      obj instanceof File || 
      obj instanceof FileList || 
      obj instanceof ArrayBuffer
    );
  }

  isFileList(obj) {
    return obj instanceof FileList;
  }
}

// Factory function to create a WebTorrent client
export function createClient() {
  return new WebTorrentClient();
}