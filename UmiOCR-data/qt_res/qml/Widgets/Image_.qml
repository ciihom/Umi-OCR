// ===================================================
// =============== 可缩放的增强Image组件 ===============
// ===================================================

import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    // ========================= 【接口】 =========================

    // 可设置
    property real scaleMax: 2.0 // 比例上下限
    property real scaleMin: 0.1 // 比例上下限
    // 只读
    property real scale: 1.0 // 图片缩放比例
    property int imageSW: 0 // 图片原始宽高
    property int imageSH: 0
    id: iRoot

    // 设置图片源，展示一张图片
    function setSource(source) {
        // 特殊字符#替换为%23
        if(source.startsWith("file:///") && source.includes("#")) {
            source = source.replace(new RegExp("#", "g"), "%23");
        }
        showImage.source = source // 设置源
    }

    // ========================= 【处理】 =========================

    // 图片组件的状态改变
    function imageStatusChanged(s) {
        // 已就绪
        if(s == Image.Ready) {
            imageSW = showImage.sourceSize.width // 记录图片原始宽高
            imageSH = showImage.sourceSize.height
            imageScaleFull() // 初始大小
        }
        else {
            imageSW = imageSH = 0
            iRoot.scale = 1 
        }
    }

    // 缩放，传入 flag>0 放大， <0 缩小 ，0回归100%。以相框中心为锚点。
    function imageScaleAddSub(flag, step=0.1) {
        if(showImage.status != Image.Ready) return
        // 计算缩放比例
        let s = 1.0 // flag==0 时复原
        if (flag > 0) {  // 放大
            s = (iRoot.scale + step).toFixed(1)
            const imageFullScale = Math.max(flickable.width/imageSW, flickable.height/imageSH)
            const max = Math.max(imageFullScale, scaleMax) // 禁止大于上限或图片填满大小
            if(s > max) s = max
        }
        else if(flag < 0) {  // 缩小
            s = (iRoot.scale - step).toFixed(1)
            if(s < 0.1) s = scaleMin // 禁止小于下限
        }

        // 目标锚点
        let gx = -flickable.width/2
        let gy = -flickable.height/2
        // 目标锚点在图片中的原比例
        let s1x = (flickable.contentX-gx)/showImageContainer.width
        let s1y = (flickable.contentY-gy)/showImageContainer.height
        // 目标锚点在图片中的新比例，及差值
        iRoot.scale = s // 更新缩放
        let s2x = (flickable.contentX-gx)/showImageContainer.width
        let s2y = (flickable.contentY-gy)/showImageContainer.height
        let sx = s2x-s1x
        let sy = s2y-s1y
        // 实际长度差值
        let lx = sx*showImageContainer.width
        let ly = sy*showImageContainer.height
        // 偏移
        flickable.contentX -= lx
        flickable.contentY -= ly
    }

    // 图片填满组件
    function imageScaleFull() {
        if(showImage.source == "") return
        iRoot.scale = Math.min(flickable.width/imageSW, flickable.height/imageSH)
        // 图片中心对齐相框
        flickable.contentY =  - (flickable.height - showImageContainer.height)/2
        flickable.contentX =  - (flickable.width - showImageContainer.width)/2
    }
    
    // ======================== 【布局】 =========================

    // 图片区域
    Rectangle {
        id: flickableContainer
        anchors.fill: parent
        color: theme.bgColor

        // 滑动区域，自动监听左键拖拽
        Flickable {
            id: flickable
            anchors.fill: parent
            contentWidth: showImageContainer.width
            contentHeight: showImageContainer.height
            clip: true
            
            // 图片容器，大小不小于滑动区域
            Item {
                id: showImageContainer
                width: Math.max( imageSW * iRoot.scale , flickable.width )
                height: Math.max( imageSH * iRoot.scale , flickable.height )
                Image {
                    id: showImage
                    anchors.centerIn: parent
                    scale: iRoot.scale
                    onStatusChanged: imageStatusChanged(status)
                }
            }

            // 滚动条
            ScrollBar.vertical: ScrollBar { }
            ScrollBar.horizontal: ScrollBar { }
        }

        // 监听滚轮缩放
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            // 滚轮缩放
            onWheel: {
                if (wheel.angleDelta.y > 0) {
                    imageScaleAddSub(1) // 放大
                }
                else {
                    imageScaleAddSub(-1) // 缩小
                }
            }
        }
    }
}