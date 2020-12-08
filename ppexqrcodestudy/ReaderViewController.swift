//
//  ReaderViewController.swift
//  ppexqrcodestudy
//
//  Created by [Peter Pan Students] on 2020/12/8.
//

import UIKit
// 相機相關的套件(或引入AVKit也行)
import AVFoundation

class ReaderViewController: UIViewController
{
    // MARK:- Outlet
    // 將相機拍攝到的畫面投射到UIView上
    @IBOutlet weak var cameraContainerView: UIView!
    // 讀出來的字串顯示在TextView上
    @IBOutlet weak var outputTextView: UITextView!
    //MARK:- values
    // 管理相機擷取的輸入輸出
    var captureSession: AVCaptureSession?
    // 預覽畫面，即將相機擷取到畫面預覽在這層上
    var previewLayer: AVCaptureVideoPreviewLayer?
    // 針對分析到的QRCode，加上框框到畫面上讓使用者知道
    var qrCodeBounds:UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 3
        return view
    }()
    
    //MARK:Functions
    public func showAnyOutputText(outputStr:String)
    {
        outputTextView.text = outputStr
    }

    //MARK:- Life Cycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    //UIViewController即將顯示的時候可以重啟掃瞄器，不過這個範例是用按鈕啟動，所以不自動復原
//    override func viewWillAppear(_ animated: Bool)
//    {
//        super.viewWillAppear(animated)
//
//        if (captureSession?.isRunning == false) {
//            captureSession?.startRunning()
//        }
//    }
    //UIViewController即將消失的時候停用掃瞄器，可以防止在背景的時候還在掃描東西
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession?.stopRunning()
        }
    }
    
    //MARK:- Target Action
    // 啟動相機掃描事件
    @IBAction func doCameraRead(_ sender: Any)
    {
        callingScanner()
    }
    
}

//MARK:- QRCode Reader Function
// extension除了額外擴充原有的class，也可以這樣寫用來區別程式碼區段
// 看個人喜好而定
extension ReaderViewController
{
    //呼叫掃瞄器
    public func callingScanner()
    {
        if let capture = captureSession//不是nil的話就啟動/停止掃瞄器
        {
            //三元運算子簡化判斷captureSession檢測執行中所要做的事情
            capture.isRunning ? capture.stopRunning() : capture.startRunning()
        }
        else
        {
            configurationScanner()//初始化
            callingScanner()//重新呼叫一次(應該不會再進來第二次)
        }
    }
    
    //設定captureSession
    private func configurationScanner()
    {
        // Setup Camera Capture
        captureSession = AVCaptureSession()
        //建立captureSession物件，並且將上面的AVCaptureDeviceInput實體設定進去
        if let deviceInput = getAVCaptureDeviceInput()
        {
            // 將取到的deviceInput塞入captureSession
            if captureSession?.addInput(deviceInput) == nil
            {
                failed() // Simulator mostly
                return
            }
        }
        //實體化一個AVCaptureMetadataOutput實體並設定至captureSession
        if captureSession?.addOutput(getAVCaptureMetadataOutput()) == nil
        {
            failed()
            return
        }
        // 設定preview的畫面要呈現在哪邊
        setQRCodePreview()
        //設置邊框
        //qrCodeBounds的畫面設定已經在宣告變數的時候做好了
        //這邊就是將.alpha調成0加到cameraContainerView上做預備顯示掃描框框的顯示
        qrCodeBounds.alpha = 0
        cameraContainerView.addSubview(qrCodeBounds)
        //原先的範例是做完設定後馬上啟動
        //這邊想分開設定Scanner和執行Scanner的部分
        //因此拉出來在callingScanner()上啟動掃瞄器
    }
    //依照取得的相機建立AVCaptureDeviceInput實體
    private func getAVCaptureDeviceInput() -> AVCaptureDeviceInput?
    {
        var videoInput: AVCaptureDeviceInput? = nil
        //取得使用相機的權限，這裡就用預設的相機
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else
        {
            print("無法獲取相機裝置")
            return videoInput
        }
        //由獲取的裝置嘗試建立AVCaptureDeviceInput實體
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            // 假如有錯誤發生、印出錯誤描述
            print(error.localizedDescription)
        }
        return videoInput
    }
    //因為要掃描的是QRCode，解析的資訊會變成metadata輸出，要娶的是AVCaptureMetadataOutput實體
    private func getAVCaptureMetadataOutput() -> AVCaptureMetadataOutput
    {
        let metadataOutput = AVCaptureMetadataOutput()
        //使用 DispatchQueue.main 來取得預設的主佇列(眾多範例、文件都這麼寫)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        // 告訴 App 我們所想要處理 metadata 的對象對象類型，解析QRCode的列舉就是[qr]
        metadataOutput.metadataObjectTypes = [.qr] // Also have things like Face, body, cats
        return metadataOutput
    }
    // 設定掃描預覽畫面範圍
    private func setQRCodePreview()
    {
        if let session = captureSession
        {
            //直接建立就不用擔心有nil的情況讓程式崩潰
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            //這邊previewLayer.frame設定可能會出點差錯
            //這是指定預覽畫面在呈現時的位置與大小
            //用view.layer.bounds表示preview在顯示的時候是整個UIViewController的view
            //如果想指定呈現在固定的小範圍就要用範例的cameraContainerView做設定
            //也許之前的版本只要addSublayer就可以塞到cameraContainerView拉好的小框框
            //但現在嘗試就是無法這麼做，或許還要多點研究
//            previewLayer!.frame = view.layer.bounds
            previewLayer!.frame = cameraContainerView.layer.bounds
            previewLayer!.videoGravity = .resizeAspectFill
            cameraContainerView.layer.addSublayer(previewLayer!)
        }
    }
    //失敗的提示
    private func failed() {
        let ac = UIAlertController(title: "Scanning failed", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
}


//MARK: - AVCaptureMetadataOutputDelegate
//要取得掃描後的資訊，就需要引用AVCaptureMetadataOutputObjectsDelegate
//實作metadataOutput這個方法就可以取到掃描之後的資料
extension ReaderViewController:AVCaptureMetadataOutputObjectsDelegate
{
    //MARK: Override
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection)
    {
        //還有看到一種是這樣取回資料
        //metadataObjects[0] as? AVMetadataMachineReadableCodeObject
        //感覺應該是相同的方式
        if let metadataObject = metadataObjects.first
        {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            //取到的字顯示出來
            showAnyOutputText(outputStr: stringValue)
            //顯示掃描到的QRCode打個框框讓使用者知道
            let qrCodeObject = previewLayer?.transformedMetadataObject(for: readableObject)
            showQRCodeBounds(frame: qrCodeObject?.bounds)
            //(選擇)完成掃描後停止繼續掃描
            callingScanner()
        }
    }
    //MARD: Functions
    //顯示框框在掃描到的QRCode上
    func showQRCodeBounds(frame: CGRect?) {
        guard let frame = frame else { return }
        
        qrCodeBounds.layer.removeAllAnimations() // resets any previous animations and cancels the fade out
        qrCodeBounds.alpha = 1
        qrCodeBounds.frame = frame//設定顯示的位置
        //加入animate讓框框自動消失
        UIView.animate(withDuration: 0.2, delay: 1, options: [], animations: { // after 1 second fade away
            self.qrCodeBounds.alpha = 0
        })
    }
}
