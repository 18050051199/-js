function inArray(arr, key, val) {
  for (let i = 0; i < arr.length; i++) {
    if (arr[i][key] === val) {
      return i;
    }
  }
  return -1;
}
var localName;
Page({

  /**
   * 页面的初始数据
   */
  data: {
    deviceId: '',
    serviceId: '',
    characteristicId: '',
  },


  openBluetoothAdapter() {
    // 检测蓝牙是否打开
    wx.openBluetoothAdapter({
      success: (res) => {
        this.setData({ getBlue: true, devices: [], })
        this.startBluetoothDevicesDiscovery()
      },
      fail: (res) => {
        if (res.errCode === 10001) {
          wx.showModal({
            title:'提示',
            content:'手机蓝牙未打开，请您打开手机蓝牙后点击扫描打印机',
            showCancel:false,
          })
        }
      }
    })
  },
  //开始搜寻附近的蓝牙外围设备
  startBluetoothDevicesDiscovery() {
    wx.startBluetoothDevicesDiscovery({
      allowDuplicatesKey: false,//是否允许重复上报同一设备
      success: (res) => {
        this.onBluetoothDeviceFound()
      },
    })
  },
  //监听寻找到新设备的事件，并将结果显示到蓝牙搜索模块
  onBluetoothDeviceFound() {
    wx.onBluetoothDeviceFound((res) => {
      res.devices.forEach(device => {
        if (!device.name && !device.localName) { return }
        let foundDevices = that.data.devices
        let idx = inArray(foundDevices, 'deviceId', device.deviceId)
        let data = {}
        if (idx === -1) {
          data[`devices[${foundDevices.length}]`] = device
        } else {
          data[`devices[${idx}]`] = device
        }
        // console.log(device)
        that.setData(data)
      })
    })
  },//蓝牙搜索模块end

  // 获取本机蓝牙适配器状态
  getBluetoothAdapterState() {
    wx.getBluetoothAdapterState({
      success: (res) => {
        if (res.discovering) {
          this.onBluetoothDeviceFound()
        } else if (res.available) {
          this.startBluetoothDevicesDiscovery()
        }
      }
    })
  },

  stopBluetoothDevicesDiscovery() {
    wx.stopBluetoothDevicesDiscovery()
  },

  //连接蓝牙go on
  //点击连接蓝牙设备
  createBLEConnection(e) {
    let ds = e.currentTarget.dataset
    let deviceId = ds.deviceId
    wx.showLoading({  mask:true,  title:'正在连接',})
    wx.createBLEConnection({
      deviceId,
      timeout:6000,
      success: (res) => {
        // if(that.data.deviceId!=''){that.closeBLEConnection();}
        localName = ds.name;
        this.getBLEDeviceServices(deviceId)

      },
      fail:(res)=>{
        wx.hideLoading()
        let e='连接失败'
        that.showToast(e)
      }
    })
    this.stopBluetoothDevicesDiscovery()
    that.setData({ getBlue: false })
  },
  //获取蓝牙设备所有服务
  getBLEDeviceServices(deviceId) {
    wx.getBLEDeviceServices({
      deviceId,
      success: (res) => {
        for (let i = 0; i < res.services.length; i++) {
          if (res.services[i].isPrimary) {
            this.getBLEDeviceCharacteristics(deviceId, res.services[i].uuid)
            return
          }
        }
      }
    })
  },
  //获取蓝牙设备某个服务中所有特征值
  getBLEDeviceCharacteristics(deviceId, serviceId) {
    wx.getBLEDeviceCharacteristics({
      deviceId,
      serviceId,
      success: (res) => {
        wx.hideLoading()
        // console.log(res)
        for (let i = 0; i < res.characteristics.length; i++) {
          let item = res.characteristics[i]
          if (item.properties.write) {//判断是否有写的特征
            that.setData({
              deviceId,
              serviceId,
              localName,
              characteristicId:item.uuid,
              connected: true,
            })
            let e='连接成功'
            that.showToast(e)
            return
            // console.log(that.data.name)
          }else {
            // console.log(that.data.name)
            let r='连接失败'
            that.showToast(r)
          }
          // if (item.properties.read) {//判断是否有读的特征}
          // if (item.properties.notify || item.properties.indicate) {}
        }
      },
      fail(res) {
        // console.error('getBLEDeviceCharacteristics', res)
      }
    })
  },//连接蓝牙end

  //断开蓝牙连接
  closeBLEConnection() {
    wx.closeBLEConnection({
      deviceId: that.data.deviceId,
      fail(){

      },
    })
    app.deviceId = "";
    that.setData({
      connected: false,
      deviceId: '',
      // canWrite: false,
    })
  },
  // 消息显示模块
  showToast(e) {
    wx.showToast({
      title: e,
      icon: 'none',
      duration: 2000
    });
  },


})
