//
//  AsyncSequenceExtensionsAppApp.swift
//  Shared
//
//  Created by Joseph Lord on 23/06/2021.
//

import SwiftUI

@main
struct AsyncSequenceExtensionsAppApp: App {
    let persistenceController = PersistenceController.shared
    let asyncPubTest = AsyncPubTest()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
