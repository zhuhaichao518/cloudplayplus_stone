import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../controller/screen_controller.dart';
import '../base/logging.dart';

class VideoInfoWidget extends StatelessWidget {
  const VideoInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenController.showVideoInfo,
      builder: (context, showVideoInfo, _) {
        return Visibility(
          visible: showVideoInfo,
          child: showVideoInfo
              ? const _VideoInfoContent()
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

/* ==========================================
 * 以下代码完全不变，仅贴出方便你直接覆盖
 * ========================================== */

/// 视频信息内容组件
class _VideoInfoContent extends StatefulWidget {
  const _VideoInfoContent();

  @override
  State<_VideoInfoContent> createState() => _VideoInfoContentState();
}

class _VideoInfoContentState extends State<_VideoInfoContent> {
  Timer? _refreshTimer;
  Map<String, dynamic> _videoInfo = {};
  Map<String, dynamic> _previousVideoInfo = {};

  @override
  void initState() {
    super.initState();
    VLOG0('VideoInfoContentState: initState called');
    _startRefreshTimer();
  }

  @override
  void dispose() {
    VLOG0('VideoInfoContentState: dispose called');
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      final session = WebrtcService.currentRenderingSession;
      if (session?.pc != null) {
        try {
          final stats = await session!.pc!.getStats();
          final newVideoInfo = _extractVideoInfo(stats);
          if (newVideoInfo.toString() != _videoInfo.toString()) {
            setState(() {
              _previousVideoInfo = Map<String, dynamic>.from(_videoInfo);
              _videoInfo = newVideoInfo;
            });
          }
        } catch (e) {
          VLOG0("failed to get video stats");
        }
      } else {
        if (_videoInfo.isNotEmpty) setState(() => _videoInfo = {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_videoInfo.isEmpty) {
      return _loadingIndicator('获取视频信息中...');
    }
    if (!_videoInfo['hasVideo']) {
      return _tipText('未检测到视频流');
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              _buildInfoItem('分辨率', '${_videoInfo['width']}×${_videoInfo['height']}'),
              _buildInfoItem('帧率', '${(_videoInfo['fps'] as num).toStringAsFixed(1)} fps'),
              _buildInfoItem('解码器', _getDecoderDisplayName(_videoInfo['decoderImplementation'], _videoInfo)),
              _buildInfoItem('丢包率', '${_calculatePacketLossRate(_videoInfo).toStringAsFixed(1)}%'),
              _buildInfoItem('往返时延', '${((_videoInfo['roundTripTime'] as num) * 1000).toStringAsFixed(0)} ms'),
              _buildInfoItem('解码时间', '${(_videoInfo['avgDecodeTimeMs'] as num).toStringAsFixed(1)} ms'),
              _buildInfoItem('抖动', '${((_videoInfo['jitter'] as num) * 1000).toStringAsFixed(1)} ms'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingIndicator(String text) => Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white))),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 10)),
        ]),
      );

  Widget _tipText(String text) => Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Text(text,
            style: TextStyle(color: Colors.white70, fontSize: 10)),
      );

  Widget _buildInfoItem(String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(color: Colors.white70, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      );

  double _calculatePacketLossRate(Map<String, dynamic> videoInfo) {
    final currentPacketsLost = videoInfo['packetsLost'] as num;
    final currentPacketsReceived = videoInfo['packetsReceived'] as num;
    
    // 如果没有上一次的数据，返回0
    if (_previousVideoInfo.isEmpty) {
      return 0.0;
    }
    
    final previousPacketsLost = _previousVideoInfo['packetsLost'] as num? ?? 0;
    final previousPacketsReceived = _previousVideoInfo['packetsReceived'] as num? ?? 0;
    
    // 计算最近一秒的增量
    final deltaPacketsLost = currentPacketsLost - previousPacketsLost;
    final deltaPacketsReceived = currentPacketsReceived - previousPacketsReceived;
    
    // 如果没有新的数据包，返回0
    if (deltaPacketsReceived <= 0) return 0.0;
    
    final deltaTotal = deltaPacketsLost + deltaPacketsReceived;
    return (deltaPacketsLost / deltaTotal) * 100;
  }

  String _getDecoderDisplayName(String implementation, Map<String, dynamic> videoInfo) {
    if (implementation == '未知' || implementation.isEmpty) return '未知';
    String name = implementation.length > 15 ? '${implementation.substring(0, 12)}...' : implementation;
    if (videoInfo['isHardwareDecoder'] == true) name += ' (硬解)';
    return name;
  }
}

/// 紧凑版视频信息组件
class CompactVideoInfoWidget extends StatelessWidget {
  const CompactVideoInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenController.showVideoInfo,
      builder: (context, showVideoInfo, _) {
        return Visibility(
          visible: showVideoInfo,
          child: showVideoInfo
              ? const _CompactVideoInfoContent()
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _CompactVideoInfoContent extends StatefulWidget {
  const _CompactVideoInfoContent();

  @override
  State<_CompactVideoInfoContent> createState() => _CompactVideoInfoContentState();
}

class _CompactVideoInfoContentState extends State<_CompactVideoInfoContent> {
  Timer? _refreshTimer;
  Map<String, dynamic> _videoInfo = {};
  Map<String, dynamic> _previousVideoInfo = {};

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      final session = WebrtcService.currentRenderingSession;
      if (session?.pc != null) {
        try {
          final stats = await session!.pc!.getStats();
          final newVideoInfo = _extractVideoInfo(stats);
          if (newVideoInfo.toString() != _videoInfo.toString()) {
            setState(() {
              _previousVideoInfo = Map<String, dynamic>.from(_videoInfo);
              _videoInfo = newVideoInfo;
            });
          }
        } catch (_) {}
      } else {
        if (_videoInfo.isNotEmpty) setState(() => _videoInfo = {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_videoInfo.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('获取视频信息中...',
            style: TextStyle(color: Colors.white70, fontSize: 10)),
      );
    }
    if (!_videoInfo['hasVideo']) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('未检测到视频流',
            style: TextStyle(color: Colors.white70, fontSize: 10)),
      );
    }

    final packetLossRate = _calculatePacketLossRate(_videoInfo);
    final rtt = ((_videoInfo['roundTripTime'] as num) * 1000).toStringAsFixed(0);
    final fps = (_videoInfo['fps'] as num).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${_videoInfo['width']}×${_videoInfo['height']} | ${fps}fps | 丢包${packetLossRate.toStringAsFixed(1)}% | RTT${rtt}ms',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  double _calculatePacketLossRate(Map<String, dynamic> videoInfo) {
    final currentPacketsLost = videoInfo['packetsLost'] as num;
    final currentPacketsReceived = videoInfo['packetsReceived'] as num;
    
    // 如果没有上一次的数据，返回0
    if (_previousVideoInfo.isEmpty) {
      return 0.0;
    }
    
    final previousPacketsLost = _previousVideoInfo['packetsLost'] as num? ?? 0;
    final previousPacketsReceived = _previousVideoInfo['packetsReceived'] as num? ?? 0;
    
    // 计算最近一秒的增量
    final deltaPacketsLost = currentPacketsLost - previousPacketsLost;
    final deltaPacketsReceived = currentPacketsReceived - previousPacketsReceived;
    
    // 如果没有新的数据包，返回0
    if (deltaPacketsReceived <= 0) return 0.0;
    
    final deltaTotal = deltaPacketsLost + deltaPacketsReceived;
    return (deltaPacketsLost / deltaTotal) * 100;
  }
}

/// 从WebRTC统计信息中提取视频信息
Map<String, dynamic> _extractVideoInfo(List<StatsReport> stats) {
  Map<String, dynamic> videoInfo = {
    'hasVideo': false,
    'width': 0,
    'height': 0,
    'fps': 0.0,
    'decoderImplementation': '未知',
    'isHardwareDecoder': false,
    'codecType': '未知',
    'avgDecodeTimeMs': 0.0,
    'framesDecoded': 0,
    'framesDropped': 0,
    'keyFramesDecoded': 0,
    'packetsLost': 0,
    'packetsReceived': 0,
    'bytesReceived': 0,
    'jitter': 0.0,
    'nackCount': 0,
    'pliCount': 0,
    'firCount': 0,
    'freezeCount': 0,
    'pauseCount': 0,
    'totalFreezesDuration': 0.0,
    'totalPausesDuration': 0.0,
    'roundTripTime': 0.0,
    'availableBandwidth': 0.0,
  };

  try {
    // 查找视频入站RTP统计
    for (var report in stats) {
      if (report.type == 'inbound-rtp') {
        final values = Map<String, dynamic>.from(report.values);
        
        // 检查是否为视频轨道
        if (values['kind'] == 'video' || values['mediaType'] == 'video') {
          videoInfo['hasVideo'] = true;
          
          // 基本视频信息
          videoInfo['width'] = values['frameWidth'] ?? 0;
          videoInfo['height'] = values['frameHeight'] ?? 0;
          videoInfo['fps'] = (values['framesPerSecond'] as num?)?.toDouble() ?? 0.0;
          
          // 解码器信息
          String decoderImpl = values['decoderImplementation'] ?? '未知';
          videoInfo['decoderImplementation'] = decoderImpl;
          videoInfo['isHardwareDecoder'] = _isHardwareDecoder(decoderImpl);
          videoInfo['powerEfficientDecoder'] = values['powerEfficientDecoder'] ?? false;
          
          // 解码性能统计
          final totalDecodeTime = (values['totalDecodeTime'] as num?)?.toDouble() ?? 0.0;
          final framesDecoded = values['framesDecoded'] ?? 0;
          videoInfo['framesDecoded'] = framesDecoded;
          
          if (framesDecoded > 0 && totalDecodeTime > 0) {
            videoInfo['avgDecodeTimeMs'] = (totalDecodeTime / framesDecoded * 1000);
          }
          
          // 质量统计
          videoInfo['framesDropped'] = values['framesDropped'] ?? 0;
          videoInfo['keyFramesDecoded'] = values['keyFramesDecoded'] ?? 0;
          videoInfo['packetsLost'] = values['packetsLost'] ?? 0;
          videoInfo['packetsReceived'] = values['packetsReceived'] ?? 0;
          videoInfo['bytesReceived'] = values['bytesReceived'] ?? 0;
          videoInfo['jitter'] = (values['jitter'] as num?)?.toDouble() ?? 0.0;
          
          // 网络控制统计
          videoInfo['nackCount'] = values['nackCount'] ?? 0;
          videoInfo['pliCount'] = values['pliCount'] ?? 0;
          videoInfo['firCount'] = values['firCount'] ?? 0;
          
          // 播放质量统计
          videoInfo['freezeCount'] = values['freezeCount'] ?? 0;
          videoInfo['pauseCount'] = values['pauseCount'] ?? 0;
          videoInfo['totalFreezesDuration'] = (values['totalFreezesDuration'] as num?)?.toDouble() ?? 0.0;
          videoInfo['totalPausesDuration'] = (values['totalPausesDuration'] as num?)?.toDouble() ?? 0.0;
          
          // 查找编解码器信息
          String? codecId = values['codecId'];
          if (codecId != null) {
            var codecReport = stats.firstWhere(
              (s) => s.type == 'codec' && s.id == codecId,
              orElse: () => StatsReport('', '', 0.0, {}),
            );
            if (codecReport.values.isNotEmpty) {
              videoInfo['codecType'] = codecReport.values['mimeType'] ?? '未知';
              videoInfo['clockRate'] = codecReport.values['clockRate'] ?? 0;
              videoInfo['payloadType'] = codecReport.values['payloadType'] ?? 0;
            }
          }
          
          break;
        }
      }
    }
    
    // 查找连接质量信息
    for (var report in stats) {
      if (report.type == 'candidate-pair') {
        final values = Map<String, dynamic>.from(report.values);
        if (values['state'] == 'succeeded' && values['nominated'] == true) {
          videoInfo['roundTripTime'] = (values['currentRoundTripTime'] as num?)?.toDouble() ?? 0.0;
          videoInfo['availableBandwidth'] = (values['availableOutgoingBitrate'] as num?)?.toDouble() ?? 0.0;
          break;
        }
      }
    }
    
  } catch (e) {
    VLOG0('提取视频信息出错: $e');
  }
  
  return videoInfo;
}

/// 判断是否为硬件解码器
bool _isHardwareDecoder(String implementation) {
  if (implementation.isEmpty) return false;
  
  // 硬件解码器关键字（不区分大小写）
  List<String> hardwareKeywords = [
    'mediacodec',     // Android MediaCodec
    'videotoolbox',   // iOS VideoToolbox
    'hardware',       // 通用硬件标识
    'hw',            // 硬件缩写
    'nvenc',         // NVIDIA
    'qsv',           // Intel Quick Sync
    'vaapi',         // Video Acceleration API
    'dxva',          // DirectX Video Acceleration
    'vdpau',         // Video Decode and Presentation API
  ];
  
  String lowerImpl = implementation.toLowerCase();
  return hardwareKeywords.any((keyword) => lowerImpl.contains(keyword));
}
