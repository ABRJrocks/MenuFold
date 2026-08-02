import AppKit
import SwiftUI

enum Brand {
  static let rose = Color(red: 0.76, green: 0.19, blue: 0.35)
  static let roseSoft = Color(red: 0.76, green: 0.19, blue: 0.35).opacity(0.13)
}

struct AppIconView: View {
  let size: CGFloat

  var body: some View {
    Image(nsImage: NSApp.applicationIconImage)
      .resizable()
      .interpolation(.high)
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}

struct MenuFoldPopoverView: View {
  @ObservedObject var model: AppModel
  let windows: WindowCoordinator

  var body: some View {
    VStack(spacing: 0) {
      header
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)

      Divider()

      ScrollView {
        VStack(spacing: 18) {
          statusPanel
          arrangementSection
          quickSettings
        }
        .padding(20)
      }

      Divider()
      footer
        .padding(.horizontal, 16)
        .frame(height: 48)
    }
    .frame(width: 380, height: 510)
    .background(.regularMaterial)
    .tint(Brand.rose)
  }

  private var header: some View {
    HStack(spacing: 12) {
      AppIconView(size: 34)

      VStack(alignment: .leading, spacing: 1) {
        Text("MenuFold")
          .font(.system(size: 15, weight: .semibold))
        Text("Menu bar organizer")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button {
        windows.showSettings()
      } label: {
        Image(systemName: "gearshape")
          .font(.system(size: 13, weight: .medium))
          .frame(width: 26, height: 26)
      }
      .buttonStyle(.plain)
      .background(Color.primary.opacity(0.06), in: Circle())
      .help("Open MenuFold settings")
      .accessibilityLabel("Settings")
    }
  }

  private var statusPanel: some View {
    VStack(alignment: .leading, spacing: 15) {
      HStack(spacing: 8) {
        Circle()
          .fill(model.isHidden ? Brand.rose : Color.green)
          .frame(width: 8, height: 8)
        Text(model.isHidden ? "Selected icons are hidden" : "Selected icons are visible")
          .font(.system(size: 13, weight: .semibold))
        Spacer()
      }

      Text(
        model.isHidden
          ? "Only icons in the Hidden zone are tucked away. Your Always visible icons stay put."
          : "Move or use a selected icon now. MenuFold can tuck that zone away automatically."
      )
      .font(.system(size: 12.5))
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)

      Button {
        model.requestToggle()
      } label: {
        HStack(spacing: 8) {
          Image(systemName: model.isHidden ? "eye" : "eye.slash")
          Text(model.isHidden ? "Reveal selected icons" : "Hide selected icons")
          Spacer()
          Text(model.shortcutDisplay)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.75))
        }
        .font(.system(size: 13, weight: .semibold))
        .padding(.horizontal, 14)
        .frame(height: 38)
        .foregroundStyle(.white)
        .background(Brand.rose, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
      }
      .buttonStyle(.plain)
      .accessibilityHint(
        model.isHidden
          ? "Shows the menu bar items left of the MenuFold boundary"
          : "Hides the menu bar items left of the MenuFold boundary")
    }
    .padding(16)
    .background(
      Color(nsColor: .controlBackgroundColor),
      in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private var arrangementSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("ARRANGEMENT")
          .font(.system(size: 10, weight: .semibold))
          .tracking(0.7)
          .foregroundStyle(.secondary)
        Spacer()
        Button("Guide") { windows.showOnboarding() }
          .buttonStyle(.link)
          .font(.system(size: 11))
      }

      MenuBarArrangementPreview(isHidden: model.isHidden)

      Text(
        "Open Guide, then hold Command and drag the real ‹‹ divider in the top menu bar. Place it between Hidden and Always visible."
      )
      .font(.system(size: 11.5))
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var quickSettings: some View {
    VStack(spacing: 0) {
      SettingToggleRow(
        icon: "arrow.clockwise",
        title: "Hide again automatically",
        subtitle: "After \(Int(model.rehideDelay)) seconds",
        isOn: Binding(get: { model.autoRehide }, set: { model.autoRehide = $0 })
      )

      Divider().padding(.leading, 36)

      SettingToggleRow(
        icon: "power",
        title: "Open at login",
        subtitle: model.launchAtLoginEnabled ? "Ready after every restart" : "Needs macOS approval",
        isOn: Binding(
          get: { model.launchAtLoginEnabled },
          set: { model.setLaunchAtLogin($0) }
        )
      )
    }
    .padding(.horizontal, 12)
    .background(
      Color(nsColor: .controlBackgroundColor),
      in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private var footer: some View {
    HStack {
      Button("Arrangement Guide") { windows.showOnboarding() }
        .buttonStyle(.plain)
        .font(.system(size: 11.5))
        .foregroundStyle(.secondary)
      Spacer()
      Button("Quit") { NSApp.terminate(nil) }
        .buttonStyle(.plain)
        .font(.system(size: 11.5))
        .foregroundStyle(.secondary)
    }
  }
}

struct SettingToggleRow: View {
  let icon: String
  let title: String
  let subtitle: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.system(size: 12.5, weight: .medium))
        Text(subtitle)
          .font(.system(size: 10.5))
          .foregroundStyle(.secondary)
      }
      Spacer()
      Toggle("", isOn: $isOn)
        .labelsHidden()
        .controlSize(.small)
    }
    .frame(height: 52)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
  }
}

struct MenuBarArrangementPreview: View {
  let isHidden: Bool

  var body: some View {
    VStack(spacing: 5) {
      HStack {
        Text("HIDDEN")
        Spacer()
        Text("ALWAYS VISIBLE")
      }
      .font(.system(size: 8.5, weight: .semibold))
      .tracking(0.45)
      .foregroundStyle(.secondary)

      HStack(spacing: 9) {
        Group {
          tinySymbol("waveform")
          tinySymbol("cloud")
          tinySymbol("bolt.fill")
        }
        .opacity(isHidden ? 0.16 : 0.72)

        Text("‹‹")
          .font(.system(size: 13, weight: .bold, design: .rounded))
          .foregroundStyle(Brand.rose)
          .accessibilityLabel("MenuFold boundary")

        Spacer(minLength: 6)

        tinySymbol("wifi")
        tinySymbol("battery.75percent")

        Image(systemName: "rectangle.3.group.fill")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Brand.rose)
      }
    }
    .padding(.horizontal, 13)
    .frame(height: 58)
    .background(
      Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous)
    )
    .animation(.easeOut(duration: 0.18), value: isHidden)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Menu bar arrangement preview")
  }

  private func tinySymbol(_ name: String) -> some View {
    Image(systemName: name)
      .font(.system(size: 11, weight: .medium))
      .foregroundStyle(.secondary)
      .frame(width: 15)
  }
}

struct OnboardingView: View {
  @ObservedObject var model: AppModel
  let dismiss: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Spacer()
        Button {
          finish()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 11, weight: .semibold))
            .frame(width: 26, height: 26)
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.06), in: Circle())
        .accessibilityLabel("Close guide")
      }
      .padding(18)

      AppIconView(size: 88)

      Text("Your menu bar, with room to breathe.")
        .font(.system(size: 26, weight: .bold))
        .tracking(-0.45)
        .multilineTextAlignment(.center)
        .padding(.top, 16)

      Text(
        "Arrangement Mode reveals every icon while you place one divider between what hides and what always stays visible."
      )
      .font(.system(size: 14))
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .frame(maxWidth: 430)
      .padding(.top, 8)

      MenuBarArrangementPreview(isHidden: false)
        .frame(width: 430)
        .padding(.top, 18)

      HStack(spacing: 8) {
        Image(systemName: "cursorarrow.motionlines")
          .foregroundStyle(Brand.rose)
        Text(
          "Arrangement Mode is active. Work in the real menu bar at the very top—this diagram is only a preview."
        )
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 12)
      .frame(width: 430, height: 40)
      .background(Brand.roseSoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
      .padding(.top, 10)

      HStack(alignment: .top, spacing: 12) {
        GuideStep(
          number: 1,
          title: "Find ‹‹ at the top",
          detail: "It now sits beside the MenuFold icon in your real menu bar."
        )
        GuideStep(
          number: 2,
          title: "Hold Command",
          detail: "Keep ⌘ held down before you click the ‹‹ divider."
        )
        GuideStep(
          number: 3,
          title: "Drag the divider",
          detail: "Move ‹‹ left and release it between the two groups."
        )
      }
      .padding(.top, 20)
      .padding(.horizontal, 30)

      Spacer()

      HStack {
        Image(
          systemName: model.launchAtLoginEnabled
            ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
        )
        .foregroundStyle(model.launchAtLoginEnabled ? Color.green : Color.orange)
        Text(
          model.launchAtLoginEnabled
            ? "MenuFold is set to open at login"
            : "Approve MenuFold in Login Items to open it automatically"
        )
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        Spacer()
        if !model.launchAtLoginEnabled {
          Button("Open Settings") { model.openLoginItemsSettings() }
            .buttonStyle(.link)
        }
        Button("Customize Shortcut") { model.onOpenSettingsRequested?() }
          .buttonStyle(.link)
      }
      .padding(.horizontal, 30)
      .padding(.bottom, 16)

      Button {
        finish()
      } label: {
        Text("Done arranging")
          .font(.system(size: 13, weight: .semibold))
          .frame(maxWidth: .infinity)
          .frame(height: 40)
          .foregroundStyle(.white)
          .background(Brand.rose, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 30)
      .padding(.bottom, 28)
      .keyboardShortcut(.defaultAction)
    }
    .frame(width: 620, height: 570)
    .background(.regularMaterial)
    .tint(Brand.rose)
  }

  private func finish() {
    model.completeOnboarding()
    dismiss()
  }
}

struct GuideStep: View {
  let number: Int
  let title: String
  let detail: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("\(number)")
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .frame(width: 22, height: 22)
        .background(Brand.rose, in: Circle())

      Text(title)
        .font(.system(size: 13, weight: .semibold))
      Text(detail)
        .font(.system(size: 11.5))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct SettingsView: View {
  @ObservedObject var model: AppModel

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        AppIconView(size: 44)
        VStack(alignment: .leading, spacing: 2) {
          Text("MenuFold Settings")
            .font(.system(size: 17, weight: .semibold))
          Text("Calm controls for a calmer menu bar")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .padding(22)

      Divider()

      Form {
        Section("General") {
          Toggle(
            "Open MenuFold at login",
            isOn: Binding(
              get: { model.launchAtLoginEnabled },
              set: { model.setLaunchAtLogin($0) }
            ))

          if let message = model.launchAtLoginMessage {
            HStack {
              Text(message)
                .foregroundStyle(.secondary)
              Spacer()
              Button("Open Login Items") { model.openLoginItemsSettings() }
            }
          }
        }

        Section("Behavior") {
          Toggle(
            "Hide revealed items automatically",
            isOn: Binding(
              get: { model.autoRehide },
              set: { model.autoRehide = $0 }
            ))

          Picker(
            "Hide after",
            selection: Binding(
              get: { model.rehideDelay },
              set: { model.rehideDelay = $0 }
            )
          ) {
            Text("5 seconds").tag(TimeInterval(5))
            Text("8 seconds").tag(TimeInterval(8))
            Text("15 seconds").tag(TimeInterval(15))
            Text("30 seconds").tag(TimeInterval(30))
          }
          .disabled(!model.autoRehide)

          LabeledContent("Keyboard shortcut") {
            HStack(spacing: 8) {
              ShortcutRecorder(displayString: model.shortcutDisplay) {
                keyCode, modifiers, keyLabel in
                model.setShortcut(
                  keyCode: keyCode,
                  modifiers: modifiers,
                  keyLabel: keyLabel
                )
              }
              .frame(width: 118, height: 28)

              Button("Reset") { model.resetShortcut() }
                .buttonStyle(.link)
                .font(.system(size: 11.5))
            }
          }

          if !model.hotKeyAvailable {
            Text(
              "\(model.shortcutDisplay) is already in use. Click the recorder and type a different combination."
            )
            .font(.system(size: 11.5))
            .foregroundStyle(.secondary)
          }
        }

        Section("Help") {
          Button("Open Arrangement Guide") { model.onShowGuideRequested?() }
          Text("Tip: quit MenuFold at any time to reveal the entire hidden section safely.")
            .font(.system(size: 11.5))
            .foregroundStyle(.secondary)
        }
      }
      .formStyle(.grouped)
      .scrollContentBackground(.hidden)
    }
    .frame(width: 560, height: 500)
    .background(Color(nsColor: .windowBackgroundColor))
    .tint(Brand.rose)
  }
}
