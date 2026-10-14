//
//  WatchlistWriteFailureAlert.swift
//  StreamIn
//
//  Tells the user when a watchlist change couldn't be saved and was undone:
//  a heart on Details or a swipe in the Watchlist tab. Attached once, at
//  `RootView`, so every screen that writes to the store is covered.
//

import SwiftUI
import Domain
import Watchlist

struct WatchlistWriteFailureAlert: ViewModifier {
    let watchlist: WatchlistStore

    /// The last failure shown, so the text doesn't go blank while the
    /// alert animates out after `dismissWriteFailure()`.
    @State private var lastShown: WatchlistWriteFailure?

    func body(content: Content) -> some View {
        content
            .onChange(of: watchlist.writeFailure) { _, failure in
                if let failure { lastShown = failure }
            }
            .alert(
                Text(title),
                isPresented: Binding(
                    get: { watchlist.writeFailure != nil },
                    set: { if !$0 { watchlist.dismissWriteFailure() } }
                )
            ) {
                // The system OK button.
            } message: {
                Text(message)
            }
    }

    private var failure: WatchlistWriteFailure? {
        watchlist.writeFailure ?? lastShown
    }

    private var title: LocalizedStringResource {
        let movieTitle = failure?.movie.title ?? ""
        return switch failure?.change {
        case .add: .watchlistSaveFailedTitle(movieTitle)
        case .remove, nil: .watchlistRemoveFailedTitle(movieTitle)
        }
    }

    private var message: LocalizedStringResource {
        switch failure?.change {
        case .add: .watchlistSaveFailedMessage
        case .remove, nil: .watchlistRemoveFailedMessage
        }
    }
}

extension View {
    func watchlistWriteFailureAlert(_ watchlist: WatchlistStore) -> some View {
        modifier(WatchlistWriteFailureAlert(watchlist: watchlist))
    }
}
