from tkinter import *

window = Tk()

window.title("Daybreak Community Church Podcast Uploader")

window.geometry('700x200')

FONT="Arial Bold"
FONT_SIZE=20

# Title
lblTitle = Label(window, font=(FONT, FONT_SIZE), text="Title")
lblTitle.grid(column=0, row=0)
txtTitle = Entry(window, font=(FONT, FONT_SIZE), width=30)
txtTitle.grid(column=1, row=0)

# Speaker (aka Artist)
lblSpeaker = Label(window, font=(FONT, FONT_SIZE), text="Speaker")
lblSpeaker.grid(column=0, row=1)
txtSpeaker = Entry(window,font=(FONT, FONT_SIZE), width=30)
txtSpeaker.grid(column=1, row=1)

# Date
lblDate = Label(window, font=(FONT, FONT_SIZE), text="Date")
lblDate.grid(column=0, row=2)
txtDate = Entry(window,font=(FONT, FONT_SIZE), width=30)
txtDate.grid(column=1, row=2)

def clicked():
    cmd = './cd2podcast.sh -t ' + txtTitle.get() + ' -a ' + txtSpeaker.get() + ' -d ' + txtDate.get()
    print(cmd)
    # res = "Welcome to " + txt.get()
    # lbl.configure(text= res)

btnGo = Button(window, font=(FONT, FONT_SIZE), text="Go!", command=clicked)
btnGo.grid(column=1, row=4)

window.mainloop()