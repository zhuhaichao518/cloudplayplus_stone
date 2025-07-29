package com.cloudwebrtc.webrtc;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;

import org.webrtc.EglBase;
import org.webrtc.MediaStream;
import org.webrtc.SurfaceViewRenderer;
import org.webrtc.VideoTrack;

public class NativeVideoActivity extends Activity {
    
    private FrameLayout videoContainer;
    private SurfaceViewRenderer videoRenderer;
    private TextView helloWorldText;
    private EglBase.Context eglBaseContext;
    private VideoTrack currentVideoTrack;
    private static NativeVideoActivity currentInstance;
    
    public static void startActivity(Context context) {
        Intent intent = new Intent(context, NativeVideoActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }
    
    public static void stopActivity() {
        if (currentInstance != null) {
            currentInstance.finish();
        }
    }
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 设置全屏
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_FULLSCREEN |
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );
        
        // 创建视频容器
        videoContainer = new FrameLayout(this);
        videoContainer.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ));
        
        setContentView(videoContainer);
        
        // 添加Hello World文本控件
        initHelloWorldText();
        
        // 暂时注释掉视频渲染相关代码，只测试Activity是否正常工作
        /*
        // 初始化 EGL 上下文
        initEglContext();
        
        // 初始化视频渲染器
        initVideoRenderer();
        
        // 设置当前实例
        currentInstance = this;
        
        // 尝试设置当前的视频流
        setupCurrentVideoStream();
        */
        
        // 设置当前实例
        currentInstance = this;
    }
    
    private void initHelloWorldText() {
        helloWorldText = new TextView(this);
        helloWorldText.setText("Hello World");
        helloWorldText.setTextSize(48);
        helloWorldText.setTextColor(android.graphics.Color.WHITE);
        helloWorldText.setGravity(android.view.Gravity.CENTER);
        
        // 设置布局参数
        FrameLayout.LayoutParams textParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        );
        textParams.gravity = android.view.Gravity.CENTER;
        helloWorldText.setLayoutParams(textParams);
        
        // 将文本控件添加到容器
        videoContainer.addView(helloWorldText);
    }
    
    private void initEglContext() {
        EglBase eglBase = EglBase.create();
        eglBaseContext = eglBase.getEglBaseContext();
    }
    
    private void initVideoRenderer() {
        videoRenderer = new SurfaceViewRenderer(this);
        
        // 初始化渲染器
        videoRenderer.init(eglBaseContext, null);
        
        // 设置渲染参数
        videoRenderer.setEnableHardwareScaler(true);
        videoRenderer.setMirror(false);
        
        // 设置布局参数
        videoRenderer.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ));
        
        // 将渲染器添加到容器
        videoContainer.addView(videoRenderer);
    }
    
    private void setupCurrentVideoStream() {
        // 从 FlutterWebRTCPlugin 获取当前的 MediaStream
        MediaStream mediaStream = getCurrentMediaStream();
        if (mediaStream != null) {
            setVideoStream(mediaStream);
        }
    }
    
    private MediaStream getCurrentMediaStream() {
        try {
            // 获取 FlutterWebRTCPlugin 的实例
            FlutterWebRTCPlugin plugin = FlutterWebRTCPlugin.sharedSingleton;
            if (plugin != null) {
                // 从 MethodCallHandlerImpl 获取当前的 MediaStream
                return getMediaStreamFromPlugin();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
    
    private MediaStream getMediaStreamFromPlugin() {
        try {
            // 通过反射获取 MethodCallHandlerImpl 中的 streams
            Class<?> methodCallHandlerClass = Class.forName("com.cloudwebrtc.webrtc.MethodCallHandlerImpl");
            java.lang.reflect.Field streamsField = methodCallHandlerClass.getDeclaredField("localStreams");
            streamsField.setAccessible(true);
            
            FlutterWebRTCPlugin plugin = FlutterWebRTCPlugin.sharedSingleton;
            java.lang.reflect.Field methodCallHandlerField = FlutterWebRTCPlugin.class.getDeclaredField("methodCallHandler");
            methodCallHandlerField.setAccessible(true);
            Object methodCallHandler = methodCallHandlerField.get(plugin);
            
            java.util.Map<String, MediaStream> streams = (java.util.Map<String, MediaStream>) streamsField.get(methodCallHandler);
            
            // 返回第一个可用的 MediaStream
            if (streams != null && !streams.isEmpty()) {
                return streams.values().iterator().next();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public void setVideoStream(MediaStream mediaStream) {
        // 移除当前的视频轨道
        if (currentVideoTrack != null) {
            currentVideoTrack.removeSink(videoRenderer);
        }
        
        // 获取新的视频轨道
        if (mediaStream != null && !mediaStream.videoTracks.isEmpty()) {
            currentVideoTrack = mediaStream.videoTracks.get(0);
            currentVideoTrack.addSink(videoRenderer);
        } else {
            currentVideoTrack = null;
        }
    }
    
    public void setVideoTrack(VideoTrack videoTrack) {
        // 移除当前的视频轨道
        if (currentVideoTrack != null) {
            currentVideoTrack.removeSink(videoRenderer);
        }
        
        // 设置新的视频轨道
        currentVideoTrack = videoTrack;
        if (currentVideoTrack != null) {
            currentVideoTrack.addSink(videoRenderer);
        }
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        
        // 暂时注释掉视频渲染器相关的清理代码
        /*
        // 清理资源
        if (currentVideoTrack != null) {
            currentVideoTrack.removeSink(videoRenderer);
        }
        if (videoRenderer != null) {
            videoRenderer.release();
        }
        eglBaseContext = null;
        */
        currentInstance = null;
    }
    
    @Override
    public void onBackPressed() {
        // 返回时关闭 Activity
        finish();
    }
}