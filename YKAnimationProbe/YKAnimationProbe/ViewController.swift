//
//  ViewController.swift
//  YKAnimationProbe
//
//  Created by Yakamoz on 2026/3/18.
//

import SwiftUI
import UIKit
import SmoothGradientUIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let host = UIHostingController(rootView: RootTabView())
        host.view.backgroundColor = .systemBackground
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
    }
}

private struct RootTabView: View {
    var body: some View {
        TabView {
            AnimationShowcaseRoot()
                .tabItem {
                    Label("Animation", systemImage: "sparkles")
                }

            NavigationStack {
                ChartVisualizationDemo()
            }
            .tabItem {
                Label("Charts", systemImage: "chart.bar.xaxis")
            }

            ThirdTabWaterfallDemo()
                .tabItem {
                    Label("Smooth", systemImage: "ellipsis.circle")
                }

            SpectacleTabDemo()
                .tabItem {
                    Label("Spectacle", systemImage: "wand.and.stars")
                }
        }
    }
}
