/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import DictionaryCoding
import os

class PrefMiddleware: MiddlewareType {

  typealias StateType = AppState
  typealias ActionType = AnyAction

  static let compatibleVersion = "168"

  let mainWindow = MainWindowMiddleware()

  // The following should only be used when Cmd-Q'ing
  func applyPref(from appState: AppState) {
    do {
      let dictionary: [String: Any] = try dictEncoder.encode(appState)
      defaults.set(dictionary, forKey: PrefMiddleware.compatibleVersion)
    } catch {
      self.log.error("AppState could not converted to Dictionary: \(error)")
    }
  }

  func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
    return { tuple in
      let result = reduce(tuple)

      guard tuple.modified else {
        return result
      }

      do {
        let dictionary: [String: Any] = try dictEncoder.encode(result.state)
        defaults.set(dictionary, forKey: PrefMiddleware.compatibleVersion)
      } catch {
        self.log.error("AppState could not converted to Dictionary: \(error)")
      }

      return result
    }
  }

  private let log = OSLog(subsystem: Defs.loggerSubsystem,
                          category: Defs.LoggerCategory.middleware) 

  class MainWindowMiddleware: MiddlewareType {

    typealias StateType = AppState
    typealias ActionType = UuidAction<MainWindow.Action>

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      return { tuple in
        let result = reduce(tuple)

        guard case .close = tuple.action.payload else {
          return result
        }

        do {
          let dictionary: [String: Any] = try dictEncoder.encode(result.state)
          defaults.set(dictionary, forKey: PrefMiddleware.compatibleVersion)
        } catch {
          self.log.error("AppState could not converted to Dictionary: \(error)")
        }

        return result
      }
    }

    private let log = OSLog(subsystem: Defs.loggerSubsystem,
                            category: Defs.LoggerCategory.middleware)
  }
}

private let defaults = UserDefaults.standard
private let dictEncoder = DictionaryEncoder()
