import SwiftUI

// MARK: - Interactive fretboard  (6 strings × sliding 5-fret window, up to fret 15)
// 坐标系：统一使用 .position(x:y:) —— 设置视图【中心点】在 GeometryReader 坐标系中的位置。
// GeometryReader 原点在左上角，所有计算以此为基准。
struct FretboardView: View {
    @ObservedObject var vm: GuitarViewModel

    // ── Fretboard navigation state ───────────────────────────────────
    /// First visible fret (1-indexed).  1 = standard open position.
    @State private var startFret     : Int  = 1
    /// Drag anchor: value of startFret when the current drag gesture began.
    @State private var dragStartFret : Int  = 1
    /// When locked the board cannot be scrolled by the user.
    @State private var isLocked      : Bool = true

    // ── Layout constants ─────────────────────────────────────────────
    private let visibleFrets = 5          // frets shown at once
    private let totalFrets   = 15         // full navigable range
    private let numStrings   = 6
    private var maxStartFret: Int { totalFrets - visibleFrets + 1 }   // 11

    // ── Inlay positions (standard guitar dots) ───────────────────────
    private let singleInlay: Set<Int> = [3, 5, 7, 9, 15]
    private let doubleInlay: Set<Int> = [12]

    // ── Colors ───────────────────────────────────────────────────────
    private let woodColor  = Color(red: 0.38, green: 0.22, blue: 0.08)
    private let fretColor  = Color(red: 0.80, green: 0.73, blue: 0.48)
    private let nutColor   = Color(red: 0.95, green: 0.90, blue: 0.70)
    private let inlayColor = Color.white.opacity(0.20)
    private let stringColors: [Color] = [
        Color(red: 0.62, green: 0.52, blue: 0.42),
        Color(red: 0.68, green: 0.58, blue: 0.46),
        Color(red: 0.74, green: 0.65, blue: 0.50),
        Color(red: 0.80, green: 0.72, blue: 0.55),
        Color(red: 0.85, green: 0.77, blue: 0.60),
        Color(red: 0.90, green: 0.83, blue: 0.66)
    ]

    private func cellBgColor(colIdx: Int, pressed: Bool) -> Color {
        pressed
            ? Color.orange.opacity(0.30)
            : (colIdx % 2 == 0 ? Color.black.opacity(0.20) : Color.black.opacity(0.08))
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let W      = geo.size.width
            let H      = geo.size.height
            let labelW : CGFloat = 40
            let labelH : CGFloat = 24
            let boardW = W - labelW
            let boardH = H - labelH
            let cellW  = boardW / CGFloat(visibleFrets)
            let cellH  = boardH / CGFloat(numStrings)

            let cellCX = { (col: Int) -> CGFloat in labelW + CGFloat(col) * cellW + cellW * 0.5 }
            let cellCY = { (s:   Int) -> CGFloat in labelH + CGFloat(s)   * cellH + cellH * 0.5 }

            ZStack {

                // ── 1. Wood background ────────────────────────────────
                RoundedRectangle(cornerRadius: 10)
                    .fill(woodColor)
                    .frame(width: boardW, height: boardH)
                    .shadow(color: .black.opacity(0.55), radius: 8, x: 0, y: 4)
                    .position(x: labelW + boardW * 0.5,
                              y: labelH + boardH * 0.5)

                // ── 2. Cell tap targets ───────────────────────────────
                ForEach(0..<numStrings, id: \.self) { s in
                    ForEach(0..<visibleFrets, id: \.self) { col in
                        let fretNum  = startFret + col
                        let isPressed = vm.fretPosition[s] == fretNum
                        Rectangle()
                            .fill(cellBgColor(colIdx: col, pressed: isPressed))
                            .frame(width: cellW - 1, height: cellH - 1)
                            .contentShape(Rectangle())
                            .position(x: cellCX(col), y: cellCY(s))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.15)) {
                                    if vm.fretPosition[s] == fretNum {
                                        vm.fretPosition[s] = 0
                                        vm.pluckString(s, fret: 0)
                                    } else {
                                        vm.fretPosition[s] = fretNum
                                        vm.pluckString(s, fret: fretNum)
                                    }
                                }
                            }
                    }
                }

                // ── 3. Nut (visible only at fret 1) ──────────────────
                if startFret == 1 {
                    Rectangle()
                        .fill(nutColor)
                        .frame(width: 5, height: boardH)
                        .position(x: labelW + 2.5, y: labelH + boardH * 0.5)
                        .transition(.opacity)
                }

                // ── 4. Fret wires ─────────────────────────────────────
                ForEach(1...visibleFrets, id: \.self) { col in
                    Rectangle()
                        .fill(fretColor)
                        .frame(width: 2.5, height: boardH)
                        .position(x: labelW + CGFloat(col) * cellW,
                                  y: labelH + boardH * 0.5)
                }

                // ── 5. Strings ────────────────────────────────────────
                ForEach(0..<numStrings, id: \.self) { s in
                    let thick = CGFloat(1.2 + Double(numStrings - s - 1) * 0.5)
                    Rectangle()
                        .fill(stringColors[s])
                        .frame(width: boardW, height: thick)
                        .position(x: labelW + boardW * 0.5, y: cellCY(s))
                }

                // ── 6. Note names (dim hint in each cell) ─────────────
                ForEach(0..<numStrings, id: \.self) { s in
                    ForEach(0..<visibleFrets, id: \.self) { col in
                        let fretNum  = startFret + col
                        let isPressed = vm.fretPosition[s] == fretNum
                        Text(GuitarAudioEngine.noteLetter(string: s, fret: fretNum))
                            .font(.system(size: min(cellW, cellH) * 0.27,
                                          weight: .medium, design: .rounded))
                            .foregroundColor(isPressed ? .orange : .white.opacity(0.20))
                            .position(x: cellCX(col),
                                      y: cellCY(s) + cellH * 0.25)
                    }
                }

                // ── 7. Inlay dots ─────────────────────────────────────
                ForEach(0..<visibleFrets, id: \.self) { col in
                    let fretNum = startFret + col
                    let cx = cellCX(col)
                    if singleInlay.contains(fretNum) {
                        Circle()
                            .fill(inlayColor)
                            .frame(width: 10, height: 10)
                            .position(x: cx, y: labelH + boardH * 0.5)
                    } else if doubleInlay.contains(fretNum) {
                        // Two dots for fret 12
                        Circle()
                            .fill(inlayColor)
                            .frame(width: 10, height: 10)
                            .position(x: cx, y: labelH + boardH * 0.33)
                        Circle()
                            .fill(inlayColor)
                            .frame(width: 10, height: 10)
                            .position(x: cx, y: labelH + boardH * 0.67)
                    }
                }

                // ── 8. Pressed dots (orange, with note name) ──────────
                ForEach(0..<numStrings, id: \.self) { s in
                    ForEach(0..<visibleFrets, id: \.self) { col in
                        let fretNum = startFret + col
                        if vm.fretPosition[s] == fretNum {
                            let dotR = min(cellW, cellH) * 0.34
                            ZStack {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: dotR * 2, height: dotR * 2)
                                    .shadow(color: .orange.opacity(0.8), radius: 6)
                                Text(GuitarAudioEngine.noteLetter(string: s, fret: fretNum))
                                    .font(.system(size: dotR * 0.82,
                                                  weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .position(x: cellCX(col), y: cellCY(s))
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }

                // ── 9. Fret number labels (top row) ───────────────────
                ForEach(0..<visibleFrets, id: \.self) { col in
                    let fretNum = startFret + col
                    // Fret 12 landmark: show Roman numeral style
                    let label = fretNum == 12 ? "XII" : "\(fretNum)"
                    Text(label)
                        .font(.system(size: 12, weight: fretNum == 12 ? .bold : .semibold,
                                      design: .monospaced))
                        .foregroundColor(fretNum == 12
                                         ? Color.orange.opacity(0.75)
                                         : .white.opacity(0.60))
                        .frame(width: cellW, height: labelH)
                        .position(x: cellCX(col), y: labelH * 0.5)
                }

                // ── 10. String name labels (left column, tap = pluck) ─
                ForEach(0..<numStrings, id: \.self) { s in
                    Text(GuitarAudioEngine.openStringNames[s])
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.80))
                        .frame(width: labelW, height: cellH)
                        .position(x: labelW * 0.5, y: cellCY(s))
                        .onTapGesture {
                            vm.pluckString(s, fret: max(0, vm.fretPosition[s]))
                        }
                }

                // ── 11. Capo bar (only when capo is in visible range) ─
                if vm.capoFret > 0,
                   (startFret...(startFret + visibleFrets - 1)).contains(vm.capoFret) {
                    let col  = vm.capoFret - startFret
                    let capoX = labelW + CGFloat(col) * cellW + 4
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(red: 0.7, green: 0.55, blue: 0.25).opacity(0.85))
                            .frame(width: 8, height: boardH)
                        Text("C\(vm.capoFret)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-90))
                    }
                    .position(x: capoX, y: labelH + boardH * 0.5)
                    .transition(.opacity)
                }

                // ── 12. Out-of-view pressed fret indicators ───────────
                // Show a small arrow badge on the board edge when a pressed
                // fret is scrolled out of view.
                ForEach(0..<numStrings, id: \.self) { s in
                    let f = vm.fretPosition[s]
                    if f > 0 {
                        let tooFar  = f > startFret + visibleFrets - 1
                        let tooNear = f < startFret
                        if tooFar || tooNear {
                            let yPos = cellCY(s)
                            let xPos: CGFloat = tooFar
                                ? labelW + boardW - 10   // right edge
                                : labelW + 10            // left edge
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.85))
                                    .frame(width: 14, height: 14)
                                Image(systemName: tooFar ? "chevron.right" : "chevron.left")
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundColor(.white)
                            }
                            .position(x: xPos, y: yPos)
                        }
                    }
                }
            }
            .frame(width: W, height: H)
            // ── Drag to scroll (unlocked only) ────────────────────────
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard !isLocked else { return }
                        let fretShift = Int((-value.translation.width / cellW).rounded())
                        let newStart  = (dragStartFret + fretShift)
                            .clamped(to: 1...maxStartFret)
                        if newStart != startFret {
                            withAnimation(.interactiveSpring(response: 0.12)) {
                                startFret = newStart
                            }
                        }
                    }
                    .onEnded { _ in
                        dragStartFret = startFret
                    }
            )
            // ── Lock / fret-range button overlay ─────────────────────
            .overlay(alignment: .topTrailing) {
                lockBadge(cellW: cellW, labelH: labelH)
                    .padding(.trailing, 6)
                    .padding(.top, 2)
            }
        }
        // Auto-scroll to chord when selected from library
        .onChange(of: vm.selectedChord) {
            autoScrollToChord()
        }
        // Keep dragStartFret in sync when startFret changes programmatically
        .onChange(of: startFret) {
            dragStartFret = startFret
        }
    }

    // MARK: - Lock Badge
    private func lockBadge(cellW: CGFloat, labelH: CGFloat) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                isLocked.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 11, weight: .bold))

                if isLocked {
                    // Show compact range label when locked
                    Text("\(startFret)–\(startFret + visibleFrets - 1)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                } else {
                    // Show "slide" hint + current range when unlocked
                    Text("← \(startFret)–\(startFret + visibleFrets - 1)品 →")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
            }
            .foregroundColor(isLocked ? Color.orange.opacity(0.90) : Color.white.opacity(0.60))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isLocked
                          ? Color.orange.opacity(0.14)
                          : Color.white.opacity(0.09))
                    .overlay(
                        Capsule()
                            .stroke(isLocked
                                    ? Color.orange.opacity(0.40)
                                    : Color.white.opacity(0.20),
                                    lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Auto-scroll helper
    private func autoScrollToChord() {
        guard let chord = vm.selectedChord else { return }
        // Find the lowest pressed fret in the chord
        let activeFrets = chord.frets.filter { $0 > 0 }
        guard let minFret = activeFrets.min() else { return }
        // Set the window so minFret is the first visible fret
        let target = minFret.clamped(to: 1...maxStartFret)
        if target != startFret {
            withAnimation(.spring(response: 0.35)) {
                startFret = target
            }
        }
    }
}

// Clamped helper is already in MetronomeEngine.swift — no duplicate needed.
