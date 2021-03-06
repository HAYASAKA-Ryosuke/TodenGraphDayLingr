# -*- encoding: utf-8 -*-

require 'gruff'
require 'csv'
require 'sinatra'
require 'date'
require 'json'

def graphgenerate(xlabels,y,x_name,y_name,graphname)
	system('rm -f ./figure/Now*.png')
        g = Gruff::Line.new
	if graphname.include?("Now")
        	g.title = "PowerUsageGraph"
        	g.data("PowerUsageGraph",y)
        	g.labels = xlabels
        	g.x_axis_label = x_name
        	g.y_axis_label = y_name
        	g.write('./figure/'+graphname+'.png')
	else
		system('rm -f ./figure/'+graphname+'.png')
        	g.title = graphname
        	g.data(graphname,y)
        	g.labels = xlabels
        	g.x_axis_label = x_name
        	g.y_axis_label = y_name
        	g.write('./figure/'+graphname+'.png')
	end
end

def filedownload(url,filename)
        system('wget '+url+' -O'+ filename)
        system('nkf -w --overwrite '+ filename)
end

def diff(h,y)
	y0=y.pop
	result =[]
	y.each do |param|
		result << (param-y0)/h
		y0=param
	end
	return result
end

def todayfileanalysis(filename,option)
        if((DateTime.now.to_time-File.stat("./data/juyo-j.csv").mtime.to_time).to_i > 0) then
                filedownload('http://www.tepco.co.jp/forecast/html/images/juyo-j.csv','./data/juyo-j.csv')
                powerdata=[]
                datatime=""
                count = 0
                CSV.foreach("./data/juyo-j.csv",encoding: "UTF-8") do |data|
                        if(count==0) then
                                datatime=data[0]
                        end
                        if(count>46) then
                                powerdata << data[2].to_f*10000/10**6#kWはわかりにくいのでMW
                        end
                        count=count+1
                end
        end
	if option != nil
		powerdata=diff(5,powerdata)
	end
        xlabels={0 => '0',12 => '1',24 => '2',36 => '3',48 => '4',60 => '5',72 => '6',84 => '7',96 => '8',108 => '9',120 => '10',132 => '11',144 => '12',156 => '13',168 => '14',180 => '15',192 => '16',204 => '17',216 => '18',228 => '19',240 => '20',252 => '21',264 => '22',276 => '23'}
        graphgenerate(xlabels,powerdata,'Hour','Power Usage[MW]',filename)
        return ""

end

def pastfileanalysis(dateyear,datemonth,dateday,option)
	optionname=''
        filename=dateyear.to_s+'-'+datemonth.to_s+'-'+dateday.to_s+'.json'
                url='http://tepco-usage-api.appspot.com/'+dateyear.to_s+'/'+datemonth.to_s+'/'+dateday.to_s+'.json'
                filedownload(url,"./data/"+filename)
                powerdata=[]
                jsondata=open("./data/"+filename).read
                jsonpowerdata = JSON.parser.new(jsondata).parse()
                jsonpowerdata.each do |data|
                        powerdata << data['usage'].to_f*10000/10**6#kWはわかりにくいのでMW
                end
		if option != nil
			powerdata=diff(1,powerdata)
			optionname='diff'
		end
                xlabels={0 => '0',1 => '1',2 => '2',3 => '3',4 => '4',5 => '5',6 => '6',7 => '7',8 => '8',9 => '9',10 => '10',11 => '11',12 => '12',13 => '13',14 => '14',15 => '15',16 => '16',17 => '17',18 => '18',19 => '19',20 => '20',21 => '21',22 => '22',23 => '23'}
                graphgenerate(xlabels,powerdata,'Hour','Power Usage[MW]','PowerUsageGraph'+dateyear.to_s+'-'+datemonth.to_s+'-'+dateday.to_s+optionname)
        return 'PowerUsageGraph'+dateyear.to_s+'-'+datemonth.to_s+'-'+dateday.to_s+optionname+'.png'
end

def LingrRequestJudge(data)
	if(data["status"] == "ok" and data["events"]) then
		data["events"].each do |e, text=e["messsage"]["text"]|
			if(text.index("!toden") != nil) then
				return True
			else
				return False
			end
		end
	else
		return False
	end
end


post '/todengraphdaylingr' do
        #data = JSON.parse(request.body)
        data = JSON.load(request.body)
	if(LingrDataJudge(data)) then
		dateparam=text.split(" ")[1].to_i
		dateyear=(Date.today-dateparam).year
		datemon=(Date.today-dateparam).mon
		dateday=(Date.today-dateparam).mday
		if(dateparam>0) then
			graphdatetime=pastfileanalysis(dateyear,datemon,dateday,text.index("diff"))	
			return 'http://v157-7-153-173.z1d1.static.cnode.jp/tmpfigure/TodenGraphDayLingr/'+graphdatetime
		else
       			filename = 'NowPowerUsageGraph'+[*1..9, *'A'..'Z', *'a'..'z'].sample(8).join
        		graphdatetime=todayfileanalysis(filename,text.index('diff'))                                     
        		return "http://v157-7-153-173.z1d1.static.cnode.jp/tmpfigure/TodenGraphDayLingr/"+filename+".png"
		end
	else
		return ""
	end
end

get '/todengraphdaylingr' do
	"Hello TodenGraphDayLingr!!"
end
