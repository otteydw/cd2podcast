# import subprocess
import os
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

def run_cd2podcast():
    message_title = txtTitle.get()
    message_speaker = txtSpeaker.get()
    message_date = txtDate.get()

    # cmd = ['./cd2podcast.sh','-t', messageTitle, '-a', messageSpeaker, '-d', messageDate]
    cmd = './cd2podcast.sh -t ' + message_title + ' -a ' + message_speaker + ' -d ' + message_date
    print(cmd)
    return_code = os.WEXITSTATUS(os.system(cmd))

    # res = "Welcome to " + txt.get()
    # lbl.configure(text= res)

btnGo = Button(window, font=(FONT, FONT_SIZE), text="Go!", command=run_cd2podcast)
btnGo.grid(column=1, row=4)

window.mainloop()