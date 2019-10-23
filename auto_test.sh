#!/bin/bash

LCD_W=800
LCD_H=480

HDMI_1080P_W=1920
HDMI_1080P_H=1080

CURRENT_RES=$(adb shell dumpsys window | grep cur= |tr -s " " | cut -d " " -f 4|cut -d "=" -f 2)
CURRENT_W=$(echo "$CURRENT_RES" | awk -Fx '{print $1}')
CURRENT_H=$(echo "$CURRENT_RES" | awk -Fx '{print $2}')


if [[ "$CURRENT_W" -eq 800 ]] && [[ "$CURRENT_H" -eq 480 ]];then
#SWIPE_X1=$(echo | awk "{print 288*"$X_SCALE"}")
SWIPE_X1=288
SWIPE_X2=288
SWIPE_Y1=240
SWIPE_Y2=0
BT_TAP_X=288
BT_TAP_Y=240
CAM_CAPTURE_X=740
CAM_CAPTURE_Y=216
CAM_BACK_X=737
CAM_BACK_Y=394
CAM_ACCEPT_X=747
CAM_ACCEPT_Y=217
GPU_RUN_X=1860
GPU_RUN_Y=315
elif [[ "$CURRENT_W" -eq 1920 ]] && [[ "$CURRENT_H" -eq 1080 ]];then
SWIPE_X1=900
SWIPE_X2=544
SWIPE_Y1=900
SWIPE_Y2=0
BT_TAP_X=900
BT_TAP_Y=342
CAM_CAPTURE_X=1770
CAM_CAPTURE_Y=504
CAM_BACK_X=1766
CAM_BACK_Y=970
CAM_ACCEPT_X=1768
CAM_ACCEPT_Y=520
CAM_SWITCH1_X=1602
CAM_SWITCH1_Y=50
CAM_SWITCH2_X=1602
CAM_SWITCH2_Y=428
GPU_RUN_X=990
GPU_RUN_Y=147
elif [[ "$CURRENT_W" -eq 1280 ]] && [[ "$CURRENT_H" -eq 720 ]];then
SWIPE_X1=600
SWIPE_X2=362
SWIPE_Y1=600
SWIPE_Y2=0
BT_TAP_X=600
BT_TAP_Y=228
CAM_CAPTURE_X=1180
CAM_CAPTURE_Y=336
CAM_BACK_X=1177
CAM_BACK_Y=646
CAM_ACCEPT_X=1178
CAM_ACCEPT_Y=346
CAM_SWITCH1_X=1080
CAM_SWITCH1_Y=30
CAM_SWITCH2_X=1070
CAM_SWITCH2_Y=261
GPU_RUN_X=660
GPU_RUN_Y=100
fi

LEVEL=normal

adb root
sleep 3

#unlock screen
adb shell input touchscreen swipe "$SWIPE_X1" "$SWIPE_X2" "$SWIPE_Y1" "$SWIPE_Y2"


# WIFI test
adb shell "svc wifi enable"


# Bluetooth test
adb shell am start -a android.settings.BLUETOOTH_SETTINGS
adb shell input tap "$BT_TAP_X" "$BT_TAP_Y"
sleep 5
adb exec-out screencap -p > test_bt_scan.png

# Video Test
CHECK_AUDIO_DEV=$(adb shell cat /proc/asound/cards)

if [[ "$(echo "$CHECK_AUDIO_DEV" | grep "no soundcards")" ]];then
  video_file=/mnt/media_rw/F556-9BAE/test_video/no-audio/Girl.mp4
  SLEEP_TIME=3
else
  video_file=/mnt/media_rw/F556-9BAE/test_video/bbb_full.ffmpeg.1920x1080.mp4.libx265_6500kbps_30fps.libfaac_stereo_128kbps_48000Hz.mp4
  SLEEP_TIME=10
fi

adb shell cp -rv "$video_file" /sdcard/Download/test.mp4
sleep 30
adb shell am start -a android.intent.action.VIEW -d "file:///sdcard/Download/test.mp4" -t "video/*"
sleep "$SLEEP_TIME"
adb exec-out screencap -p > test_vpu.png
sleep 60

# GPU test
adb install ./gpu-stress.apk
adb shell am start -n com.kortenoeverdev.GPUbench/com.unity3d.player.UnityPlayerNativeActivity
sleep 10
adb shell input tap "$GPU_RUN_X" "$GPU_RUN_Y"
sleep 30
adb exec-out screencap -p > test_gpu.png
sleep 150
adb exec-out screencap -p > test_gpu_result.png


# Camera test

if [[ "$(adb shell ls /dev/video0)" ]];then
  if [[ "$(adb shell ls /dev/video1)" ]];then
    CAM_NUM=2
  else
    CAM_NUM=1
  fi
else
  CAM_NUM=0
fi

echo "Camera number is ""$CAM_NUM"
adb shell "am start -a android.media.action.IMAGE_CAPTURE" && sleep 1

for i in {1..2}
do
  sleep 5
  adb shell input tap "$CAM_CAPTURE_X" "$CAM_CAPTURE_Y"
  sleep 2
  adb exec-out screencap -p > camera1-capture_test-"$i".png
  if [ "$i" -eq 10 ];then
    adb shell input tap "$CAM_ACCEPT_X" "$CAM_ACCEPT_Y"
  else
    adb shell input tap "$CAM_BACK_X" "$CAM_BACK_Y"
  fi
done

if [[ "$CAM_NUM" == "2" ]];then
  pid=$(adb shell ps | grep camera2 | awk '{print $2}')
  adb shell kill pid

  adb shell "am start -a android.media.action.IMAGE_CAPTURE" && sleep 1
  adb shell input tap "$CAM_SWITCH1_X" "$CAM_SWITCH1_Y"
  sleep 1
  adb shell input tap "$CAM_SWITCH2_X" "$CAM_SWITCH2_Y"

  for i in {1..2}
  do
    sleep 5
      adb shell input tap "$CAM_CAPTURE_X" "$CAM_CAPTURE_Y"
      sleep 2
      adb exec-out screencap -p > camera2-capture_test-"$i".png
    if [ "$i" -eq 10 ];then
      adb shell input tap "$CAM_ACCEPT_X" "$CAM_ACCEPT_Y"
    else
      adb shell input tap "$CAM_BACK_X" "$CAM_BACK_Y"
    fi
 done
fi


# Web Browser test (queen's music video from youtube)
# Ethernet first
adb shell am start -a android.intent.action.VIEW -d https://www.youtube.com/watch?v=fJ9rUzIMcZQ
sleep 40
adb exec-out screencap -p > youtube_test_eth.png
sleep 600

# WiFi Second
adb shell "ifconfig eth0 down"
adb shell am start -a android.intent.action.VIEW -d https://www.youtube.com/watch?v=fJ9rUzIMcZQ
sleep 40
adb exec-out screencap -p > youtube_test_wifi.png
