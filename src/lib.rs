use js_sys::{Object, Promise};
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsValue;
use wasm_bindgen_futures::JsFuture;

// JS interop for the WebTorrent client
#[wasm_bindgen(module = "/js/shim.js")]
extern "C" {
    #[wasm_bindgen(js_name = WebTorrentClient)]
    pub type JsWebTorrentClient;

    #[wasm_bindgen(js_name = createClient)]
    pub fn create_client() -> JsWebTorrentClient;

    #[wasm_bindgen(method, js_name = seed)]
    pub fn seed(
        this: &JsWebTorrentClient,
        input: &JsValue,
        opts: &JsValue,
        onseed: &JsValue,
    ) -> JsValue;

    #[wasm_bindgen(method, js_name = add)]
    pub fn add(
        this: &JsWebTorrentClient,
        torrent_id: &JsValue,
        opts: &JsValue,
        ontorrent: &JsValue,
    ) -> JsValue;

    #[wasm_bindgen(method, js_name = createServer)]
    pub fn create_server(this: &JsWebTorrentClient, options: &JsValue, force: bool) -> JsValue;

    #[wasm_bindgen(method, js_name = getTorrent)]
    pub fn get_torrent(this: &JsWebTorrentClient, torrent_id: &JsValue) -> Promise;

    #[wasm_bindgen(method, js_name = remove)]
    pub fn remove(this: &JsWebTorrentClient, torrent_id: &JsValue, opts: &JsValue, cb: &JsValue);

    #[wasm_bindgen(method, js_name = throttleDownload)]
    pub fn throttle_download(this: &JsWebTorrentClient, rate: f64);

    #[wasm_bindgen(method, js_name = throttleUpload)]
    pub fn throttle_upload(this: &JsWebTorrentClient, rate: f64);

    #[wasm_bindgen(method, js_name = destroy)]
    pub fn destroy(this: &JsWebTorrentClient, cb: &JsValue);

    #[wasm_bindgen(method, js_name = isReadable)]
    pub fn is_readable(this: &JsWebTorrentClient, obj: &JsValue) -> bool;

    #[wasm_bindgen(method, js_name = isFileList)]
    pub fn is_file_list(this: &JsWebTorrentClient, obj: &JsValue) -> bool;
}

// Wrapper for the WebTorrent client
#[wasm_bindgen]
pub struct WebTorrentClient {
    inner: JsWebTorrentClient,
}

#[wasm_bindgen]
impl WebTorrentClient {
    // Fix: Use static method pattern instead of constructor
    #[wasm_bindgen(js_name = new)]
    pub fn new() -> Self {
        Self {
            inner: create_client(),
        }
    }

    #[wasm_bindgen]
    pub async fn seed(&self, input: JsValue, opts_str: String) -> Result<JsValue, JsValue> {
        // Parse JSON options from string
        let opts = js_sys::JSON::parse(&opts_str).unwrap_or(JsValue::from(Object::new()));
        let promise = self.inner.seed(&input, &opts, &JsValue::UNDEFINED);
        JsFuture::from(Promise::from(promise)).await
    }

    #[wasm_bindgen]
    pub async fn add(&self, torrent_id: String) -> Result<JsValue, JsValue> {
        let opts = Object::new();
        let promise = self.inner.add(
            &JsValue::from_str(&torrent_id),
            &JsValue::from(opts),
            &JsValue::UNDEFINED,
        );
        JsFuture::from(Promise::from(promise)).await
    }

    #[wasm_bindgen]
    pub fn create_server(&self, options: Option<String>, force: bool) -> JsValue {
        let opts = match options {
            Some(opts_str) => {
                js_sys::JSON::parse(&opts_str).unwrap_or(JsValue::from(Object::new()))
            }
            None => JsValue::from(Object::new()),
        };
        self.inner.create_server(&opts, force)
    }

    #[wasm_bindgen]
    pub async fn get_torrent(&self, torrent_id: String) -> Result<JsValue, JsValue> {
        let promise = self.inner.get_torrent(&JsValue::from_str(&torrent_id));
        JsFuture::from(promise).await
    }

    #[wasm_bindgen]
    pub fn remove(&self, torrent_id: String) {
        let opts = Object::new();
        self.inner.remove(
            &JsValue::from_str(&torrent_id),
            &JsValue::from(opts),
            &JsValue::UNDEFINED,
        );
    }

    #[wasm_bindgen]
    pub fn throttle_download(&self, rate: f64) {
        self.inner.throttle_download(rate);
    }

    #[wasm_bindgen]
    pub fn throttle_upload(&self, rate: f64) {
        self.inner.throttle_upload(rate);
    }

    #[wasm_bindgen]
    pub fn destroy(&self) {
        self.inner.destroy(&JsValue::UNDEFINED);
    }

    #[wasm_bindgen]
    pub fn is_readable(&self, obj: JsValue) -> bool {
        self.inner.is_readable(&obj)
    }

    #[wasm_bindgen]
    pub fn is_file_list(&self, obj: JsValue) -> bool {
        self.inner.is_file_list(&obj)
    }
}
