from tkinter import *
import pandas as pd
from PIL import ImageTk, Image

###################### pull data from excel ##############################
data = pd.read_excel('Data_Task_Raw_Data.xlsx',sheet_name='Data')
campaign_names = data['Campaign'].str.split('_').tolist()
data_frame_new = pd.DataFrame(campaign_names,columns="CompanyName campaignType Country adType".split())

############## interface ##############
root = Tk()
root.title('Origami Logic Examination')
root.iconbitmap('images/fav.ico')
root.geometry('{}x{}'.format(560, 160))

# create the top frame
top_frame = Frame(root, width=450, height=150, pady=3)

########## core function ###############
def tagger(*args):
    try:
        value = variable.get()
        final_df = pd.concat([data,data_frame_new[value]],axis=1)
        final_df.to_excel('output/tagged_data.xlsx', index=False)
        #flash message
        message = Label(top_frame,text='Success!!',bg='light green').grid(row=10,column=3,padx=10)
    except ValueError:
        message = Label(top_frame,text='Oops!!',bg='light red').grid(row=10,column=3,padx=10)#### end of function

# layout all of the main containers
root.grid_rowconfigure(1, weight=1)
root.grid_columnconfigure(0, weight=1)

top_frame.grid(row=0, sticky="ew")

# create the widgets for the top frame
model_label = Label(top_frame, text='Select a campaign attribute & click the button')
attributes_label = Label(top_frame, text='Attributes:')

#dropdown
variable = StringVar(root)
variable.set("Select One") # default value
entry = OptionMenu(top_frame, variable, "CompanyName", "campaignType", "Country", "adType")

#button
btn = Button(top_frame, text="     **Add to DataFrame**     ", command=tagger,bg="#ff884d")

#########  add logo   #######
img = ImageTk.PhotoImage(Image.open("images/logo.png"))
imglabel = Label(root, image=img).grid(row=12, column=1)

# layout the widgets in the top frame
model_label.grid(row=0, columnspan=6)
attributes_label.grid(row=1, column=0)
entry.grid(row=1, column=2)
btn.grid(row=1, column=16)

root.mainloop()   ################################ end of interface
