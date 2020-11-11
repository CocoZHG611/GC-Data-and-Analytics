import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

xls=pd.ExcelFile('RPA analysis.xlsx')
df1=pd.read_excel(xls,sheet_name="PARTNER_GROWTH_RAW")
df2=pd.read_excel(xls,sheet_name="CLUSTERING_RAW")
df3=pd.read_excel(xls,sheet_name="PA_RAW")
df4=pd.read_excel(xls,sheet_name="PROJECT_SR_RAW")
df5=pd.read_excel(xls,sheet_name="PROJECT_SR_CHANNEL_RAW")
df6=pd.read_excel(xls,sheet_name="PROJECT_SR_POD_RAW")
df7=pd.read_excel(xls,sheet_name="PROJECT_SR_EMP_RAW")
df8=pd.read_excel(xls,sheet_name="PROJECT_SR_EMP_BOTH_RAW")


#Analyze partner growth with active and total partners
def Partner_Growth(df):
    fig, ax = plt.subplots()
    ax.plot(df['Years'], df['active_partners'],color='blue',label='Active Partners')
    ax.plot(df['Years'], df['total_partners'],color='orange',label='Total Partners')
    ax.set(xlabel='Date', ylabel='# of partners',
       title='Active v.s. Total')
    plt.xticks(rotation=90)
    ax.legend(loc="center left",
          bbox_to_anchor=(1, 0, 0.5, 1))
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df['Years'], df['total_growth'])
    ax.set(xlabel='Date', ylabel='Growth Rate',
       title='Total Growth')
    plt.xticks(rotation=90)
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df['Years'], df['perc_active'])
    ax.set(xlabel='Date', ylabel='%Active',
       title='%Active')
    plt.xticks(rotation=90)
    plt.show()
    
Partner_Growth(df1)


#Clustering of partners    
def Clustering(df):
    plt.scatter(df.loc[df['act_success1']=='H-H','projects1'],df.loc[df['act_success1']=='H-H','success_rate1'],color='blue',label='H-H')
    plt.scatter(df.loc[df['act_success1']=='H-L','projects1'],df.loc[df['act_success1']=='H-L','success_rate1'],color='yellow',label='H-l')
    plt.scatter(df.loc[df['act_success1']=='L-H','projects1'],df.loc[df['act_success1']=='L-H','success_rate1'],color='green',label='L-H')
    plt.scatter(df.loc[df['act_success1']=='L-L','projects1'],df.loc[df['act_success1']=='L-L','success_rate1'],color='black',label='L-L')
    plt.xlim(-500,9000)
    plt.ylim(-0.005,1.005)
    plt.xlabel('Projects')
    plt.ylabel('Success rate')
    plt.title('Clustering')
    plt.vlines(100, ymin=-1.5, ymax=3, 
           colors='red', linewidth=2)
    plt.hlines(0.02, xmin=-500, xmax=9000,
           colors='red', linewidth=2)
    plt.legend(loc="center left",
          bbox_to_anchor=(1, 0, 0.5, 1))
    plt.grid(True)
    plt.show()
    
Clustering(df2)


#PA of referrals and projects
def PA(df):
    fig, ax = plt.subplots()
    ax.pie(df['REFERRAL_Amount'][:-1], autopct='%1.1f%%',
        startangle=90)
    ax.legend(df['REFERRAL_Amount'][:-1], labels=df['REFERRAL_COUNCIL_NAME'][:-1],
          title="REFERRAL_COUNCIL_NAME",
          loc="center left",
          bbox_to_anchor=(1, 0, 0.5, 1))
    ax.axis('equal') 
    plt.title('REFERRAL PA')
    plt.show()
    fig, ax = plt.subplots()
    ax.pie(df['PROJECT_Amount'][:-1],  autopct='%1.1f%%',
        startangle=90)
    ax.legend(df['PROJECT_Amount'][:-1], labels=df['PROJECT_COUNCIL_NAME'][:-1],
          title="PROJECT_COUNCIL_NAME",
          loc="center left",
          bbox_to_anchor=(1, 0, 0.5, 1))
    ax.axis('equal') 
    plt.title('PROJECT PA')
    plt.show()
    
PA(df3)


#Analyze project growth rate with success rate and yield
def PSR(df):
    fig, ax = plt.subplots()
    ax.plot(df['CREATE_YEAR'],df['yield'], color='green',label='yield')
    ax.plot(df['CREATE_YEAR'], df['success_rate'],label='success rate')
    ax.plot(df['CREATE_YEAR'],df['total_growth'], color='blue',label='total growth')
    ax.set(xlabel='Date', ylabel='Rate',
       title='GC publish success-rate&yield&total-growth')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()

PSR(df4)


#Analyze GC success rate, yield, speed for publish and non-publish projects
def PSRC(df):
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','success_rate'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','success_rate'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='success_rate',
       title='GC non-publish vs publish success rate')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','yield'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','yield'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='yield',
       title='GC non-publish vs publish yield')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','ATTACH_speed'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','ATTACH_speed'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='time',
       title='GC non-publish vs publish ATTACH_speed')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','GTC_speed'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','GTC_speed'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='time',
       title='GC non-publish vs publish GTC-speed')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','TPV_speed'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','TPV_speed'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='time',
       title='GC non-publish vs publish tpv-speed')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    
PSRC(df5)


#Analyze different pods' success rate, yield, speed for publish and non-publish projects
def PSRP(df):
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','success_rate'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','success_rate'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='success_rate',
       title=df['pod'].iloc[0]+' non-publish vs publish success rate')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','yield'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','yield'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='yield',
       title=df['pod'].iloc[0]+' non-publish vs publish yield')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show() 
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','ATTACH_speed'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','ATTACH_speed'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='time',
       title=df['pod'].iloc[0]+' non-publish vs publish ATTACH_speed')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','GTC_speed'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','GTC_speed'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='time',
       title=df['pod'].iloc[0]+' non-publish vs publish GTC-speed')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    fig, ax = plt.subplots()
    ax.plot(df.loc[df['Publish_Channel']!='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']!='recruiting partner','TPV_speed'],color='blue',label='non-publish')
    ax.plot(df.loc[df['Publish_Channel']=='recruiting partner','CREATE_YEAR'], df.loc[df['Publish_Channel']=='recruiting partner','TPV_speed'],color='orange',label='publish')
    ax.set(xlabel='Date', ylabel='time',
       title=df['pod'].iloc[0]+' non-publish vs publish tpv-speed')
    ax.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.xticks(rotation=90)
    plt.show()
    
PSRP(df6.loc[df6['pod']=='FS - Beijing FS',:])
PSRP(df6.loc[df6['pod']=='FS - Shanghai FS',:])
PSRP(df6.loc[df6['pod']=='FS - South China FS',:])
PSRP(df6.loc[df6['pod']=='FS - Greater China Private Equity',:])


#Analyze individuals success rate, yield, speed for publish and non-publish projects
def PSRE(df):
    sns.regplot(df.loc[df['Publish_Channel']!='recruiting partner','TPV_speed'],df.loc[df['Publish_Channel']!='recruiting partner','success_rate'],label='non-publish')
    sns.regplot(df.loc[df['Publish_Channel']=='recruiting partner','TPV_speed'],df.loc[df['Publish_Channel']=='recruiting partner','success_rate'],label='publish')
    plt.xlabel('TPV speed'); 
    plt.ylabel('Success rate')
    plt.title('GC non-publish vs publish success rate&tpv-speed')
    plt.ylim(-0.005,1.25)
    plt.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.show()   
    sns.regplot(df.loc[df['Publish_Channel']!='recruiting partner','yield'],df.loc[df['Publish_Channel']!='recruiting partner','success_rate'],label='non-publish')
    sns.regplot(df.loc[df['Publish_Channel']=='recruiting partner','yield'],df.loc[df['Publish_Channel']=='recruiting partner','success_rate'],label='publish')
    plt.xlabel('yield'); 
    plt.ylabel('Success rate')
    plt.title('GC non-publish vs publish success rate&yield')
    plt.ylim(-0.005,1.25)
    plt.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.show()   
    sns.regplot(df.loc[df['Publish_Channel']!='recruiting partner','TPV_speed'],df.loc[df['Publish_Channel']!='recruiting partner','yield'],label='non-publish')
    sns.regplot(df.loc[df['Publish_Channel']=='recruiting partner','TPV_speed'],df.loc[df['Publish_Channel']=='recruiting partner','yield'],label='publish')
    plt.xlabel('TPV speed'); 
    plt.ylabel('yield')
    plt.title('GC non-publish vs publish yield&tpv-speed')
    plt.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.show()   

PSRE(df7)

#For individuals who do publish and non-publish projects at same time,
#analyze their success rate, yield, speed for publish and non-publish projects
PSRE(df8)