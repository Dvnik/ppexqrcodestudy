//
//  GeneratorViewController.swift
//  ppexqrcodestudy
//
//  Created by [Peter Pan Students] on 2020/12/8.
//

import UIKit

class GeneratorViewController: UIViewController
{
    //MARK:- Outlet
    @IBOutlet weak var imgQRCode: UIImageView!
    
    @IBOutlet weak var sldImageSize: UISlider!
    
    @IBOutlet weak var textViewInput: UITextView!
    
    @IBOutlet weak var correctionLevelSegmentControl: UISegmentedControl!
    
    //MARK:- Values
    var qrcodeImage:CIImage?//儲存轉換後的qrcode影像
    
    
    //MARK:- LifeCycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //MARK:- TargetAction
    
    @IBAction func generatorQRCode(_ sender: Any)
    {
        if qrcodeImage == nil
        {
            if let filterImage = createQRCodeForString(textViewInput.text)
            {
                qrcodeImage = filterImage
                displayQRCodeImage()
            }
        }
        else
        {
            imgQRCode.image = nil
            qrcodeImage = nil
        }
    }
    //額外功能，調整圖片大小
    @IBAction func changeImageViewScale(_ sender: Any)
    {
        imgQRCode.transform = CGAffineTransform(scaleX: CGFloat(sldImageSize.value), y: CGFloat(sldImageSize.value))
    }
    //MARK: - Functions
    //因為矯正等級用correctionLevelSegmentControl控制，所以獨立生成CIImage方法
    func createQRCodeForString(_ text: String) -> CIImage?
    {
        // 將文字資料轉換成Data
        let data = text.data(using: .isoLatin1)
        //用CIFilter轉換，
        //我們需要做的是建立新的 CoreImage 濾波器（利用 CIQRCodeGenerator ）來指定一些參數，
        //然後即可獲得輸出的圖片，也就是 QR Code 圖片。
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        //這是要轉換成 QR Code 圖片的初始資料
        qrFilter?.setValue(data, forKey: "inputMessage")
        // 這裡表示有多少額外的錯誤更正資料要被附加到輸出的 QR Code 圖片中
        // 其數值是 4 種字串之一： L 、 M 、 Q 、 H ，分別對應到不同的錯誤復原能力，
        // 依序為 7% 、 15% 、 25% 、 30% 。數值越大，輸出的 QR Code 圖片也就越大。
        // --------不信任segment的文字，就自己將選擇到的selectedSegmentIndex做轉換-------
//        let values = ["L", "M", "Q", "H"]
//        // Trick to limit the result to the bounds (0, array.maxIndex) - max(_MIN_, min(_value_, _MAX_))
//        let index = max(0, min(correctionLevelSegmentControl.selectedSegmentIndex, (values.count-1)))
//        let correctionLevel = values[index]
        //將取出的校正等級設定進去
//        qrFilter?.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        // --------END 不信任segment的文字的做法-------
        // 如果信任UI上的文字，可直接取出來使用
        let selectCorrectionLevel = correctionLevelSegmentControl.titleForSegment(at: correctionLevelSegmentControl.selectedSegmentIndex)
        //將取出的校正等級設定進去
        qrFilter?.setValue(selectCorrectionLevel ?? "M", forKey: "inputCorrectionLevel")
        
        return qrFilter?.outputImage
    }
    // 重新部署QRCode圖片，主要用在調整清晰度
    func displayQRCodeImage()
    {
        // UIImage的長寬和qrcode的CIImage輸出之後的大小相除取得一個調整大小的比例值
        if let resizeImage = qrcodeImage
        {
            let scaleX = imgQRCode.frame.size.width / resizeImage.extent.size.width
            let scaleY = imgQRCode.frame.size.height / resizeImage.extent.size.height
            // 取得調整後的圖片大小，用CGAffineTransform去做縮放
            let transformedImage = resizeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            // 將結果顯示到UIImage上
            imgQRCode.image = UIImage(ciImage: transformedImage)
        }
    }
}
