//
//  PingbackEncoder.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/30.
//

import Foundation

class PingbackEncoder: NSCopying {
    @objc func copy(with zone: NSZone? = nil) -> Any {
        let encoder = PingbackEncoder()
        encoder.storage = self.storage.mutableCopy() as! NSMutableDictionary
        return encoder
    }

    var storage = NSMutableDictionary()

    func container<Key>(keyedBy type: Key.Type) -> PingbackKeyedEncodingContainer<Key> where Key : CodingKey {
        return PingbackKeyedEncodingContainer(storage: self.storage)
    }

    func stringForGetMethod() -> String {
        return storage.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
    }

    func stringForPostMethod() -> String {
        if let data = try? JSONSerialization.data(withJSONObject: storage, options: []),
            let string = String(data: data, encoding: .utf8) {
            return string
        } else {
            #if DEBUG
            assert(false, "Pingback: string for post null")
            #endif
            return ""
        }
    }
}

class PingbackKeyedEncodingContainer<K> where K : CodingKey {
    typealias Key = K
    var storage: NSMutableDictionary

    init(storage: NSMutableDictionary) {
        self.storage = storage
    }

    func encode(_ value: Int, forKey key: KeyedEncodingContainer<K>.Key) {
        self.storage[key.stringValue] = "\(value)"
    }
    func encode(_ value: String, forKey key: KeyedEncodingContainer<K>.Key) {
        self.storage[key.stringValue] = value
    }
    func encode(_ value: [String: Any], forKey key: KeyedEncodingContainer<K>.Key) {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: []) else { return }
        self.storage[key.stringValue] = String(data: data, encoding: .utf8)
    }
    func encode(_ value: [Any], forKey key: KeyedEncodingContainer<K>.Key) {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: []) else { return }
        self.storage[key.stringValue] = String(data: data, encoding: .utf8)
    }
}



func encodeBasicParams(_ encoder: PingbackEncoder) {
    enum BasicParams: String, CodingKey {
        case u // IDFA； 如果IDFA为空,则取MAC地址（去除分隔符+转大写，然后MD5，32位小写）； 如果MAC地址为固定值，则使用openUDID.
        case pu // 登录用户的爱奇艺Passportid，非登录用户为空。
        case p1 // iOS版本: 2_22_221
        case v // 启动的客户端的版本号。
        case rn // 用于防止在发送相同参数时客户端缓存而导致投递未能到达服务器。
        case dfp // 介绍文档。http://wiki.qiyi.domain/pages/viewpage.action?pageId=96207418
        case de // 此次冷启动到冷启动退出整个生命周期内的唯一EventID。 md5(u+毫秒级时间戳)。
    }
    let container = encoder.container(keyedBy: BasicParams.self)
    container.encode("", forKey: .u)
    container.encode("", forKey: .pu)
    container.encode("", forKey: .p1)
    container.encode("", forKey: .v)
    container.encode("", forKey: .rn)
    container.encode("", forKey: .dfp)
    container.encode("", forKey: .de)
}

// MARK: - dict define

enum s_site: String {
    case iqiyi // 爱奇艺
    case tencent // 腾讯
    case youku // 优酷
    case pptv // 聚力视频
    case tvguoapp // 电视果APP
    case sohu // 搜狐视频
    case jiliguala // 叽里呱啦
    case mgtv // 芒果tv
    case woshipin // 沃视频
    case huyatv // 虎牙直播
    case app_bilibili // 哔哩哔哩
    case baiduyunapp // 百度网盘
    case letv // 乐视视频
    case letv_sports // 乐视体育
    case cbox // 央视影音
    case love_v // 咪咕视频
    case cartoon // 动画屋
    case app_mgtv // 芒果视频
    case hanjutv // 韩剧TV
    case renrentv // 人人视频
    case tangdou // 糖豆
    case douyutv // 斗鱼直播
}

enum s_content: String {
    case tvguoapp_iqiyi // 电视果APP内爱奇艺
    case tvguoapp_baiduyun // 电视果APP内百度云h5
    case tvguoapp_zhibo // 电视果APP内直播频道h5
    case tvguoapp_wolive // 电视果APP内沃电视h5
    case tvguoapp_wfd // 电视果APP内无线显示
    case tvguoapp_picture // 电视果APP内投相册
    case tvguoapp_mirror // 电视果APP内屏幕镜像
}

class PingbackControlPanel {

    let encoder = PingbackEncoder()

    // 功能区块
    enum Blocks: String {
        case player_v_remote // 半屏控制页
        case player_h_remote // 全屏控制页
        case notice_remote // 通知中心遥控
        case lock_remote // 锁屏遥控
    }

    /// rseat 点击的位置信息
    enum Events: String {
        case pause // 暂停
        case resumeply // 继续播放
        case fast_forward // 快进
        case fast_backward // 快退
        case volumeup // 音量+
        case volumedown // 音量-
        case drag // 拖拽进度条
        case stop // 退出投屏
        case switchdevice // 切换设备
        case speed // 设置播放速度
        case next // 下一集
        case switchra // 切换码流
        case dm // 弹幕开关
        case aivoice // 语音
        case earphone // 秘听开关
        case wifidisplay // 无线显示
        case switchtrack // 切换音轨
        case pictureset // 画面设置
        case timedoff // 定时关闭
        case isot // 只看TA
        case screenshot // 截图
        case cycle // 单片循环
        case subtitle // 加载字幕
        case soundeffect // 音效
        case db // 杜比开关
        case jump // 自动跳过片头片尾
        case switchline // 线路切换
        case hdmi // 信源切换
        case deviceset // 设备管理入口点击设置
        case titleclick // 点击视频标题
        case openapp // 打开APP
    }

    enum BasicParamKeys: String, CodingKey {
        case t // 日志类型
        case hu // 会员状态标识
        case rpage // 页面类型(或模板)标识
        case stime // 系统时间
        case ce // 一次rpage展现的EventID
        case block // 功能区块(移动端中的card)
        case rseat // 功能区块(移动端中的card)
        case s_site // 播放站点/内容（一级）
        case s_content // 播放站点/内容（二级）
    }

    enum ExternalParamKeys: String, CodingKey {
        case seekFrom = "drgfr"
        case seekTo = "drgto"
        case vdieoQuality = "ra"
        case volumeMode = "mode"
        case speed
        case danmuState = "isdm"
        case earphoneState = "earphone"
        case pictureMode = "picmode"
        case onlyWatchStar = "isot"
        case dollbyState = "duby"
        case audioEffect = "effect"
        case videoRepeat = "cycle"
        case timeoutState = "timedoff"
        case inputSource = "hdmi"
        case jumpHeadTail = "jump"
        case faskSeekMode = "clickmode"
    }

    static func pingback(block: Blocks, event: Events, addParams: (PingbackKeyedEncodingContainer<ExternalParamKeys>) -> Void) {
        let pCp = PingbackControlPanel()
        let container = pCp.encoder.container(keyedBy: BasicParamKeys.self)
        container.encode(block.rawValue, forKey: .block)
        container.encode(event.rawValue, forKey: .rseat)
        let externalContainer = pCp.encoder.container(keyedBy: ExternalParamKeys.self)
        addParams(externalContainer)
        pCp.send()
    }

    private func send() {
        print(encoder.stringForGetMethod())
        print("send pingback")
    }
}

func testPingbackEncoder() {
    PingbackControlPanel.pingback(block: .lock_remote, event: .aivoice) { (container) in
        container.encode("1", forKey: .earphoneState)
    }
}
