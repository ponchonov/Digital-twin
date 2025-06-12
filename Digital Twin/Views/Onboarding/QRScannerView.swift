import SwiftUI
import AVFoundation
import PhotosUI

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = false
    @State private var scannedCode: String?
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var scanError: Error?
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            ZStack {
                if isScanning {
                    QRScannerRepresentable(scannedCode: $scannedCode, error: $scanError)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack {
                        Text("Scan QR Code")
                            .font(.title2)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .padding(.top, 40)

                        Spacer()

                        PhotosPicker(selection: $selectedItem,
                                   matching: .images) {
                            Label("Choose from Library", systemImage: "photo")
                                .font(.headline)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 40)
                    }
                } else {
                    Color(.systemBackground)
                        .overlay {
                            VStack(spacing: 24) {
                                Image(systemName: "person.and.background.dotted")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.blue)
                                    .padding(.bottom, 20)
                                
                                Text("Digital Twin Setup")
                                    .font(.title)
                                    .bold()
                                
                                Text("Your Digital Twin is an AI-powered companion that learns from your data to provide personalized insights and assistance.")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 32)
                                
                                Text("To get started, scan the QR code provided by your Digital Twin service.")
                                    .font(.callout)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 32)
                                
                                Button(action: requestCameraPermission) {
                                    Label("Start Scanning", systemImage: "qrcode.viewfinder")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 32)
                                .padding(.top, 20)
                                
                                Button("Skip for Now") {
                                    dismiss()
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 40)
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: scannedCode) { _, newCode in
                if let code = newCode {
                    processQRCode(code)
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                               context: nil,
                                               options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
                       let ciImage = CIImage(image: image),
                       let feature = detector.features(in: ciImage).first as? CIQRCodeFeature,
                       let messageString = feature.messageString {
                        processQRCode(messageString)
                    }
                }
            }
            .alert("QR Code Result", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully saved") {
                        // Trigger app to refresh its state
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1))
                            appState.refreshRequired = true
                        }
                    }
                    if !alertMessage.contains("Error") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                isScanning = granted
                if !granted {
                    alertMessage = "Camera permission denied"
                    showAlert = true
                }
            }
        }
    }

    private func processQRCode(_ code: String) {
        do {
            guard let jsonData = code.data(using: .utf8),
                  let qrData = try? JSONDecoder().decode(QRCodeData.self, from: jsonData) else {
                throw NSError(domain: "QRScan", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid QR code format"])
            }

            try KeychainManager.shared.saveAPIURL(qrData.apiURL)
            NetworkManager.shared.setupApolloClient()

            alertMessage = "API URL successfully saved!"
            showAlert = true

        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct QRScannerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QRScannerView()
                .environmentObject(AppState())
        }
    }
}

struct QRScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var error: Error?

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerRepresentable

        init(_ parent: QRScannerRepresentable) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let stringValue = metadataObject.stringValue {
                parent.scannedCode = stringValue
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCaptureMetadataOutputObjectsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
}
