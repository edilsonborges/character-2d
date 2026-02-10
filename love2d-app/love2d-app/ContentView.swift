//
//  ContentView.swift
//  love2d-app
//
//  Created by Edilson on 10/02/26.
//

import SwiftUI

struct ContentView: View {
    @State private var game = GameState()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                // Game canvas
                GameView(game: game)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Character list panel
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Convidados")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                game.addRandomNPC()
                            }
                        } label: {
                            Label("Adicionar", systemImage: "plus.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    Divider().background(Color.white.opacity(0.2))

                    // Scrollable character list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Cat rows
                            ForEach(Array(game.cats.enumerated()), id: \.element.id) { index, cat in
                                CharacterRow(
                                    icon: "cat.fill",
                                    iconColor: cat.color,
                                    name: cat.name,
                                    isBirthday: cat.birthday,
                                    onToggleBirthday: { game.toggleCatBirthday(index: index) },
                                    onRemove: nil
                                )
                            }

                            // Dog rows
                            ForEach(Array(game.dogs.enumerated()), id: \.element.id) { index, dog in
                                CharacterRow(
                                    icon: "dog.fill",
                                    iconColor: Color(r: dog.color.0, g: dog.color.1, b: dog.color.2),
                                    name: dog.name,
                                    isBirthday: false,
                                    onToggleBirthday: {},
                                    onRemove: nil
                                )
                            }

                            // NPC rows
                            ForEach(Array(game.npcs.enumerated()), id: \.element.id) { index, npc in
                                CharacterRow(
                                    icon: npc.gender == .girl ? "figure.dress.line.vertical.figure" : "figure.stand",
                                    iconColor: npc.palette.body,
                                    name: npc.name,
                                    isBirthday: npc.birthday,
                                    onToggleBirthday: { game.toggleBirthday(npcIndex: index) },
                                    onRemove: {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            game.removeNPC(at: index)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 340)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Character row

struct CharacterRow: View {
    let icon: String
    let iconColor: Color
    let name: String
    let isBirthday: Bool
    let onToggleBirthday: () -> Void
    let onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            // Name
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            // Birthday toggle
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    onToggleBirthday()
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 11))
                    Text(isBirthday ? "Aniversariante" : "Aniversario")
                        .font(.system(size: 10))
                }
                .foregroundStyle(isBirthday ? .yellow : .white.opacity(0.4))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isBirthday ? Color.yellow.opacity(0.2) : Color.white.opacity(0.05))
                .clipShape(Capsule())
            }

            // Remove button
            if let onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.red.opacity(0.6))
                }
            } else {
                // Placeholder for alignment
                Color.clear.frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
