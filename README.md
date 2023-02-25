# Ubuntu Stuff

Scripts, css, etc. for my Ubuntu Desktop

***

## Nemo dark theme

See [``nemo\gtk.css file``](./nemo/gtk.css)\
Ubuntu Path: ``~/.config/gtk-3.0/gtk.css``

Nemo dark
![Nemo dark](./img/NemoDark.png)

***

## Nemo custom action

See folder [nemo](./nemo/).\
Copy file or files to your home .local... folder: ~/.local/share/nemo/actions

- Integrate meld diff tool to context menu: [``meld diff f1 f2 [f3].nemo_action``](./nemo/meld/meld%20diff%20f1%20f2%20%5Bf3%5D.nemo_action)

- Integrate the [Gnome Terminator](https://en.wikipedia.org/wiki/GNOME_Terminator) (Multiple terminals in one window) to context menu: 
[open.terminator.multi.folder.nemo_action](./nemo/Terminator/open.terminator.multi.folder.nemo_action).\
The Action uses the following bash script: [open.terminator.multi.folder.sh](./nemo/Terminator/open.terminator.multi.folder.sh) copy it to nemo/action folder too.\
And set mode to executable: ``chmod +x open.terminator.multi.folder.sh``

***

## Nautilus (file manager for GNOME 'Files') helper scripts

See folder [nautilus](./nautilus/).\
Copy file to your home .local... folder: ~/.local/share/nautilus/scripts.\
Allow script to be run by nautilus with the command: ``chmod +x 'meld diff f1 f2 [f3]'`` 

- Integrate meld diff tool to context menu: [``meld diff f1 f2 [f3]``](./nautilus/meld%20diff%20f1%20f2%20%5Bf3%5D)

***
