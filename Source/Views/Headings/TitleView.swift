import SwiftUI

/*
 * A simple title view
 */
struct TitleView: View {

    var body: some View {

        Text("Mobile Web Integration")
            .font(.title)
            .underline()
            .foregroundColor(Colors.lightBlue)
            .padding(.bottom)
    }
}
