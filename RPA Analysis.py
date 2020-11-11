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
def Clustering1(df):
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
    print('Active 1:YTD success projects>100:\n H-H partners\n',df.loc[df['act_success1']=='H-H','REFERRER_CM_NAME1'])
    
def Clustering2(df):    
    plt.scatter(df.loc[df['act_success2']=='H-H','projects2'],df.loc[df['act_success2']=='H-H','success_rate2'],color='blue',label='H-H')
    plt.scatter(df.loc[df['act_success2']=='H-L','projects2'],df.loc[df['act_success2']=='H-L','success_rate2'],color='yellow',label='H-l')
    plt.scatter(df.loc[df['act_success2']=='L-H','projects2'],df.loc[df['act_success2']=='L-H','success_rate2'],color='green',label='L-H')
    plt.scatter(df.loc[df['act_success2']=='L-L','projects2'],df.loc[df['act_success2']=='L-L','success_rate2'],color='black',label='L-L')
    plt.xlim(-500,9000)
    plt.ylim(-0.005,1.005)
    plt.xlabel('Projects')
    plt.ylabel('Success rate')
    plt.title('Clustering')
    plt.legend(loc="center left",
          bbox_to_anchor=(1, 0, 0.5, 1))
    plt.grid(True)
    plt.show()
    print('Active 2:Referrs at least 10 lead every month:\n H-H partners\n',df.loc[df['act_success2']=='H-H','REFERRER_CM_NAME2'])
    
def Clustering3(df):    
    plt.scatter(df.loc[df['act_success3']=='H-H','projects3'],df.loc[df['act_success3']=='H-H','success_rate3'],color='blue',label='H-H')
    plt.scatter(df.loc[df['act_success3']=='H-L','projects3'],df.loc[df['act_success3']=='H-L','success_rate3'],color='yellow',label='H-l')
    plt.scatter(df.loc[df['act_success3']=='L-H','projects3'],df.loc[df['act_success3']=='L-H','success_rate3'],color='green',label='L-H')
    plt.scatter(df.loc[df['act_success3']=='L-L','projects3'],df.loc[df['act_success3']=='L-L','success_rate3'],color='black',label='L-L')
    plt.xlim(-500,9000)
    plt.ylim(-0.005,1.005)
    plt.xlabel('Projects')
    plt.ylabel('Success rate')
    plt.title('Clustering')
    plt.legend(loc="center left",
          bbox_to_anchor=(1, 0, 0.5, 1))
    plt.grid(True)
    plt.show()
    print('Active 3:Referrs at least 1 lead every month:\n H-H partners\n',df.loc[df['act_success1']=='H-H','REFERRER_CM_NAME3'])
    
Clustering1(df2)
Clustering2(df2)
Clustering3(df2)


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
    '''fig, ax = plt.subplots()
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
    plt.show()'''
    
PSRC(df5)


#Analyze different pods' success rate, yield, speed for publish and non-publish projects
def PSRP(df):
    fig, ax = plt.subplots(2,4,sharex=True,sharey=True)
    ax[0,0].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='Corp - Greater China Corporate'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='Corp - Greater China Corporate'),'success_rate'],label='Corp - Greater China Corporate non-publish')
    ax[0,0].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='Corp - Greater China Corporate'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='Corp - Greater China Corporate'),'success_rate'],label='Corp - Greater China Corporate publish')
    ax[0,0].set_title('Corp')
    ax[0,1].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Beijing FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Beijing FS'),'success_rate'],label='FS - Beijing FS non-publish')
    ax[0,1].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Beijing FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Beijing FS'),'success_rate'],label='FS - Beijing FS publish')    
    ax[0,1].set_title('BJFS')
    ax[0,2].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Credit'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Credit'),'success_rate'],label='FS - Greater China Credit non-publish')
    ax[0,2].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Credit'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Credit'),'success_rate'],label='FS - Greater China Credit publish')    
    ax[0,2].set_title('GC credit')
    ax[0,3].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Private Equity'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Private Equity'),'success_rate'],label='FS - Greater China Private Equity non-publish')
    ax[0,3].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Private Equity'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Private Equity'),'success_rate'],label='FS - Greater China Private Equity publish')    
    ax[0,3].set_title('GCPrE')
    ax[1,0].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Public Equity'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Public Equity'),'success_rate'],label='FS - Greater China Public Equity non-publish')
    ax[1,0].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Public Equity'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Public Equity'),'success_rate'],label='FS - Greater China Public Equity publish')    
    ax[1,0].set_title('GCPuE')
    ax[1,0].xaxis.set_visible(False)
    ax[1,1].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Shanghai FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Shanghai FS'),'success_rate'],label='FS - Shanghai FS non-publish')
    ax[1,1].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Shanghai FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Shanghai FS'),'success_rate'],label='FS - Shanghai FS publish')    
    ax[1,1].set_title('SHFS')
    ax[1,1].xaxis.set_visible(False)
    ax[1,2].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - South China FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - South China FS'),'success_rate'],label='FS - South China FS non-publish')
    ax[1,2].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - South China FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - South China FS'),'success_rate'],label='FS - South China FS publish')    
    ax[1,2].set_title('SCFS')
    ax[1,2].xaxis.set_visible(False)
    ax[1,3].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='PSF'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='PSF'),'success_rate'],label='PSF non-publish')
    ax[1,3].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='PSF'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='PSF'),'success_rate'],label='PSF publish')    
    ax[1,3].set_title('PSF')
    ax[1,3].xaxis.set_visible(False)
    ax[1,3].legend(('non-publish','publish'))
    ax[1,0].tick_params(axis='x', labelrotation=90)
    ax[1,1].tick_params(axis='x', labelrotation=90)
    ax[1,2].tick_params(axis='x', labelrotation=90)
    ax[1,3].tick_params(axis='x', labelrotation=90)
    fig.suptitle('Different pods non-publish vs publish success rate')
    plt.show()
    fig, ax = plt.subplots(2,4,sharex=True,sharey=True)
    ax[0,0].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='Corp - Greater China Corporate'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='Corp - Greater China Corporate'),'yield'],label='Corp - Greater China Corporate non-publish')
    ax[0,0].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='Corp - Greater China Corporate'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='Corp - Greater China Corporate'),'yield'],label='Corp - Greater China Corporate publish')
    ax[0,0].set_title('Corp')
    ax[0,1].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Beijing FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Beijing FS'),'yield'],label='FS - Beijing FS non-publish')
    ax[0,1].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Beijing FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Beijing FS'),'yield'],label='FS - Beijing FS publish')    
    ax[0,1].set_title('BJFS')
    ax[0,2].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Credit'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Credit'),'yield'],label='FS - Greater China Credit non-publish')
    ax[0,2].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Credit'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Credit'),'yield'],label='FS - Greater China Credit publish')    
    ax[0,2].set_title('GC credit')
    ax[0,3].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Private Equity'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Private Equity'),'yield'],label='FS - Greater China Private Equity non-publish')
    ax[0,3].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Private Equity'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Private Equity'),'yield'],label='FS - Greater China Private Equity publish')    
    ax[0,3].set_title('GCPrE')
    ax[1,0].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Public Equity'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Greater China Public Equity'),'yield'],label='FS - Greater China Public Equity non-publish')
    ax[1,0].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Public Equity'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Greater China Public Equity'),'yield'],label='FS - Greater China Public Equity publish')    
    ax[1,0].set_title('GCPuE')
    ax[1,0].xaxis.set_visible(False)
    ax[1,1].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Shanghai FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - Shanghai FS'),'yield'],label='FS - Shanghai FS non-publish')
    ax[1,1].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Shanghai FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - Shanghai FS'),'yield'],label='FS - Shanghai FS publish')    
    ax[1,1].set_title('SHFS')
    ax[1,1].xaxis.set_visible(False)
    ax[1,2].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - South China FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='FS - South China FS'),'yield'],label='FS - South China FS non-publish')
    ax[1,2].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - South China FS'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='FS - South China FS'),'yield'],label='FS - South China FS publish')    
    ax[1,2].set_title('SCFS')
    ax[1,2].xaxis.set_visible(False)
    ax[1,3].plot(df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='PSF'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']!='recruiting partner')&(df['pod']=='PSF'),'yield'],label='PSF non-publish')
    ax[1,3].plot(df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='PSF'),'CREATE_YEAR'], df.loc[(df['Publish_Channel']=='recruiting partner')&(df['pod']=='PSF'),'yield'],label='PSF publish')    
    ax[1,3].set_title('PSF')
    ax[1,3].xaxis.set_visible(False)
    ax[1,3].legend(('non-publish','publish'))
    ax[1,0].tick_params(axis='x', labelrotation=90)
    ax[1,1].tick_params(axis='x', labelrotation=90)
    ax[1,2].tick_params(axis='x', labelrotation=90)
    ax[1,3].tick_params(axis='x', labelrotation=90)
    fig.suptitle('Different pods non-publish vs publish yield')
    plt.show() 
    '''fig, ax = plt.subplots()
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
    plt.show()'''
    
PSRP(df6)


#Analyze individuals success rate, yield, speed for publish and non-publish projects
def PSRE(df):
    '''sns.regplot(df.loc[df['Publish_Channel']!='recruiting partner','TPV_speed'],df.loc[df['Publish_Channel']!='recruiting partner','success_rate'],label='non-publish')
    sns.regplot(df.loc[df['Publish_Channel']=='recruiting partner','TPV_speed'],df.loc[df['Publish_Channel']=='recruiting partner','success_rate'],label='publish')
    plt.xlabel('TPV speed'); 
    plt.ylabel('Success rate')
    plt.title('GC non-publish vs publish success rate&tpv-speed')
    plt.ylim(-0.005,1.25)
    plt.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.show()'''   
    sns.regplot(df.loc[df['Publish_Channel']!='recruiting partner','yield'],df.loc[df['Publish_Channel']!='recruiting partner','success_rate'],label='non-publish')
    sns.regplot(df.loc[df['Publish_Channel']=='recruiting partner','yield'],df.loc[df['Publish_Channel']=='recruiting partner','success_rate'],label='publish')
    plt.xlabel('yield'); 
    plt.ylabel('Success rate')
    plt.title('GC non-publish vs publish success rate&yield')
    plt.ylim(-0.005,1.25)
    plt.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.show()   
    '''sns.regplot(df.loc[df['Publish_Channel']!='recruiting partner','TPV_speed'],df.loc[df['Publish_Channel']!='recruiting partner','yield'],label='non-publish')
    sns.regplot(df.loc[df['Publish_Channel']=='recruiting partner','TPV_speed'],df.loc[df['Publish_Channel']=='recruiting partner','yield'],label='publish')
    plt.xlabel('TPV speed'); 
    plt.ylabel('yield')
    plt.title('GC non-publish vs publish yield&tpv-speed')
    plt.legend(loc="center left",
       bbox_to_anchor=(1, 0, 0.5, 1))
    plt.show()'''

PSRE(df7)

#For individuals who do publish and non-publish projects at same time,
#analyze their success rate, yield, speed for publish and non-publish projects
PSRE(df8)