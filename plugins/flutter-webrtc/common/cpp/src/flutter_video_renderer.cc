#include "flutter_video_renderer.h"
//#include <sstream>
namespace flutter_webrtc_plugin {

//TODO(Haichao):check if we can save the memory usage here.
FlutterVideoRenderer::FlutterVideoRenderer(TextureRegistrar* registrar,
                                           BinaryMessenger* messenger)
    : registrar_(registrar) {
  texture_ =
      std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
          [this](size_t width,
                 size_t height) -> const FlutterDesktopPixelBuffer* {
            return this->CopyPixelBuffer(width, height);
          }));

  texture_id_ = registrar_->RegisterTexture(texture_.get());

  std::string channel_name =
      "FlutterWebRTC/Texture" + std::to_string(texture_id_);
  event_channel_ = EventChannelProxy::Create(messenger, channel_name);
}

const FlutterDesktopPixelBuffer* FlutterVideoRenderer::CopyPixelBuffer(
    size_t width,
    size_t height) const {
  mutex_.lock();
  if (pixel_buffer_.get() && frame_.get()) {
    if (pixel_buffer_->width != frame_->width() ||
        pixel_buffer_->height != frame_->height()) {
      size_t buffer_size =
          (size_t(frame_->width()) * size_t(frame_->height())) * (32 >> 3);
      rgb_buffer_.reset(new uint8_t[buffer_size]);
      pixel_buffer_->width = frame_->width();
      pixel_buffer_->height = frame_->height();
    }

    frame_->ConvertToARGB(RTCVideoFrame::Type::kABGR, rgb_buffer_.get(), 0,
                          static_cast<int>(pixel_buffer_->width),
                          static_cast<int>(pixel_buffer_->height));

    pixel_buffer_->buffer = rgb_buffer_.get();
    mutex_.unlock();
    return pixel_buffer_.get();
  }
  mutex_.unlock();
  return nullptr;
}

#if defined(_WINDOWS)
// We use a dedicated background renderer benefits from DWM instead of
// texturegistar api.
//TODO Haichao :: make it properly
BackGroundRenderer* backgroundrenderer_;
HANDLE hThread = nullptr;
//0: not created
//1: creating
//2: creationsucceed
//we current only need 1 because we release bgr on ui thread.
//std::atomic<int> creationsate(0);

std::atomic<bool> thread_running(false);
DWORD WINAPI ThreadFunc(LPVOID lpParam) {
  if (!backgroundrenderer_) {
    backgroundrenderer_ = new BackGroundRenderer(
        nullptr /*frame->GetNativeImage()->Device()*/, g_main_hwnd_);
  }
    
    // Main message loop
    MSG msg = {0};
    while (WM_QUIT != msg.message && thread_running) {
        if (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
        if (msg.message== (WM_APP + 996)) {
          auto* task = reinterpret_cast<std::function<void()>*>(msg.wParam);
          (*task)();
          delete task;
          continue;
        }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
        } else {
        backgroundrenderer_->RenderTexture(
            /* frame->GetNativeImage()->Texture*/ nullptr, 200, 200);
        }
    }

    backgroundrenderer_->Release();
    backgroundrenderer_ = nullptr;

    return 0;
}


void RunOnUIThread(std::function<void()> callback)
{
    auto* task = new std::function<void()>(std::move(callback));
    PostMessage(g_main_hwnd_, (WM_APP + 996), reinterpret_cast<WPARAM>(task),
                0);
}
#endif

/*
void RunOnBackGroundRenderThread(std::function<void()> callback) {
  auto* task = new std::function<void()>(std::move(callback));
  
}*/

bool test_local_screen = false;

void FlutterVideoRenderer::OnFrame(scoped_refptr<RTCVideoFrame> frame) {
  //if (frame->GetNativeImage()!=nullptr)
//#if defined(_WINDOWS_TEST)
#if defined(_WINDOWS)
   if (test_local_screen && g_main_hwnd_) {
    /* if (!backgroundrenderer_) {
        thread_running = true;
      }
      hThread = CreateThread(
          NULL,                   // default security attributes
          0,                      // use default stack size  
          ThreadFunc,             // thread function name
          NULL,                   // argument to thread function 
          0,                      // use default creation flags 
          NULL);                  // returns the thread identifier */

// option 2: run on UI thread*/
    RunOnUIThread(
        [/* frame = frame*/]
      {
          if (!backgroundrenderer_) {
              backgroundrenderer_ = new BackGroundRenderer(
                nullptr /*frame->GetNativeImage()->Device()*/,
                GetAncestor(g_main_hwnd_,GA_ROOT));
          }
          backgroundrenderer_->RenderTexture(
          /* frame->GetNativeImage()->Texture*/ nullptr, 0,0 /* frame->width(),
          frame->height()*/);
      }
      );
      return;
   }
#endif
  if (!first_frame_rendered) {
    EncodableMap params;
    params[EncodableValue("event")] = "didFirstFrameRendered";
    params[EncodableValue("id")] = EncodableValue(texture_id_);
    event_channel_->Success(EncodableValue(params));
    pixel_buffer_.reset(new FlutterDesktopPixelBuffer());
    pixel_buffer_->width = 0;
    pixel_buffer_->height = 0;
    first_frame_rendered = true;
  }
  if (rotation_ != frame->rotation()) {
    EncodableMap params;
    params[EncodableValue("event")] = "didTextureChangeRotation";
    params[EncodableValue("id")] = EncodableValue(texture_id_);
    params[EncodableValue("rotation")] =
        EncodableValue((int32_t)frame->rotation());
    event_channel_->Success(EncodableValue(params));
    rotation_ = frame->rotation();
  }
  if (last_frame_size_.width != frame->width() ||
      last_frame_size_.height != frame->height()) {
    EncodableMap params;
    params[EncodableValue("event")] = "didTextureChangeVideoSize";
    params[EncodableValue("id")] = EncodableValue(texture_id_);
    params[EncodableValue("width")] = EncodableValue((int32_t)frame->width());
    params[EncodableValue("height")] = EncodableValue((int32_t)frame->height());
    event_channel_->Success(EncodableValue(params));

    last_frame_size_ = {(size_t)frame->width(), (size_t)frame->height()};
  }
  mutex_.lock();
  frame_ = frame;
  mutex_.unlock();

  /*haichao:test registar api performance.
  auto now = std::chrono::high_resolution_clock::now();

  auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                now.time_since_epoch())
                .count();

  std::stringstream ss;
  ss << "Milliseconds since epoch: " << ms << "\n";
  OutputDebugStringA(ss.str().c_str());
  */
  registrar_->MarkTextureFrameAvailable(texture_id_);
}

void FlutterVideoRenderer::SetVideoTrack(scoped_refptr<RTCVideoTrack> track) {
  if (track_ != track) {
    if (track_)
      track_->RemoveRenderer(this);
    track_ = track;
    last_frame_size_ = {0, 0};
    first_frame_rendered = false;
    if (track_)
      track_->AddRenderer(this);
  }
}

bool FlutterVideoRenderer::CheckMediaStream(std::string mediaId) {
  if (0 == mediaId.size() || 0 == media_stream_id.size()) {
    return false;
  }
  return mediaId == media_stream_id;
}

bool FlutterVideoRenderer::CheckVideoTrack(std::string mediaId) {
  if (0 == mediaId.size() || !track_) {
    return false;
  }
  return mediaId == track_->id().std_string();
}

FlutterVideoRendererManager::FlutterVideoRendererManager(
    FlutterWebRTCBase* base)
    : base_(base) {}

void FlutterVideoRendererManager::CreateVideoRendererTexture(
    std::unique_ptr<MethodResultProxy> result) {
  std::unique_ptr<FlutterVideoRenderer> texture(
      new FlutterVideoRenderer(base_->textures_, base_->messenger_));
  int64_t texture_id = texture->texture_id();
  renderers_[texture_id] = std::move(texture);
  EncodableMap params;
  params[EncodableValue("textureId")] = EncodableValue(texture_id);
  result->Success(EncodableValue(params));
}

void FlutterVideoRendererManager::SetMediaStream(int64_t texture_id,
                                                 const std::string& stream_id,
                                                 const std::string& ownerTag) {
  scoped_refptr<RTCMediaStream> stream =
      base_->MediaStreamForId(stream_id, ownerTag);

  auto it = renderers_.find(texture_id);
  if (it != renderers_.end()) {
    FlutterVideoRenderer* renderer = it->second.get();
    if (stream.get()) {
      auto video_tracks = stream->video_tracks();
      if (video_tracks.size() > 0) {
        renderer->SetVideoTrack(video_tracks[0]);
        renderer->media_stream_id = stream_id;
      }
    } else {
      renderer->SetVideoTrack(nullptr);
    }
  }
}

void FlutterVideoRendererManager::VideoRendererDispose(
    int64_t texture_id,
    std::unique_ptr<MethodResultProxy> result) {
#if defined(_WINDOWS)
  RunOnUIThread([]
  {
      if (backgroundrenderer_) {
          //backgroundrenderer_ ->Release();
          delete backgroundrenderer_;
          backgroundrenderer_ = nullptr;
      }
  }
  );
  if (hThread){
    thread_running = false;
    WaitForSingleObject(hThread, 1000);
    CloseHandle(hThread);
  }
#endif
  auto it = renderers_.find(texture_id);
  if (it != renderers_.end()) {
    base_->textures_->UnregisterTexture(texture_id);
    renderers_.erase(it);
    result->Success();
    return;
  }
  result->Error("VideoRendererDisposeFailed",
                "VideoRendererDispose() texture not found!");
}

}  // namespace flutter_webrtc_plugin
