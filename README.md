# laptop-dotfiles

A more practical, laptop-focused version of my dotfiles.

I already have a main set of dotfiles, but this repo is a cleaner and more usable setup built for **university, coding, and everyday laptop use**. The goal here is simple: keep things nice, but actually comfortable to use for long sessions.

> still a work in progress



<img width="900" alt="image" src="https://github.com/user-attachments/assets/ddaf209c-26e0-407e-9b2d-352b08bf7124" />

---

## what this is for

This setup is mainly what I use when I’m:

- coding
- working on projects
- studying / taking notes
- reading docs / PDFs
- just using my laptop daily

So instead of going all out on visuals, I tried to keep things **clean, compact, and practical**.

---

## main ideas behind this setup

- use less screen space
- make it comfortable for long sessions
- keep everything visually consistent
- avoid unnecessary clutter while still keeping a polished look

---

## wallpaper

This repo includes a small wallpaper system located in the scripts folder at:

`~/.config/hypr/scripts/wallpaper.sh`

Main features:

- default fixed wallpaper
- **dynamic theme generation using `pywal`**
- colors automatically applied across the system (Waybar, UI, etc.)
- a small button located on the Waybar
- a simple script to change wallpapers using `wofi`

Every time the wallpaper changes, the **entire theme updates accordingly**, which keeps the setup consistent without needing manual tweaking.

Nothing fancy, just fast and usable.

<p align="center">
  <img width="400" src="https://github.com/user-attachments/assets/1cc0177c-b9f7-4dda-b156-05d3f3f72d13" />
</p>

<p align="center">
  <img width="400" src="https://github.com/user-attachments/assets/3db12e02-3dbf-496b-a7c2-d451ee56e944" />
</p>

---

## laptop usage

This setup is slightly more tuned for laptop use:

- battery visibility and usage control
- more vertical space with reduced Waybar thickness
- brightness / OSD tools
- easier WiFi and Bluetooth setup with Orbit (also themed dynamically)
- better space usage overall
- more comfortable for long sessions

The idea is to keep the interface lightweight and usable while still benefiting from the dynamic theming.

<p align="center">
  <img width="400" src="https://github.com/user-attachments/assets/2429729f-c37c-4ba0-8609-ec9fa17acb7a" />
</p>

<p align="center">
  <img width="400" src="https://github.com/user-attachments/assets/f1a1514f-fd9a-4763-ac57-91eaa4d0727d" />
</p>

---

## work in progress

This repo is not final.

I keep adjusting things as I use the setup, especially around:

- theming consistency
- scripts
- Waybar modules
- overall workflow

---

## install

```bash
git clone https://github.com/Amine-Woo/laptop-dotfiles.git
cd laptop-dotfiles
