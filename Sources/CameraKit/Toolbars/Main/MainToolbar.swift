/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays controls to capture, switch cameras, and view the last captured media item.
*/

import SwiftUI

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct MainToolbar<CameraModel: Camera>: View {
    @State var camera: CameraModel
    
    var body: some View {
        HStack(alignment: .center) {
            Color.clear.frame(width: 50, height: 50)

            Spacer()
            
            CaptureButton(camera: camera)
                .frame(width: 60, height: 60)
            
            Spacer()
            
            CameraSwitchButton(camera: camera)
        }
        .frame(height: 60)
    }
}

#Preview {
    Group {
        MainToolbar(camera: PreviewCameraModel())
    }
}
