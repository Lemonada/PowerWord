from flask import Flask, flash, request, redirect, url_for
from flask_restful import Api, Resource, reqparse
from pathlib import Path

UPLOAD_FOLDER = 'D:\\git\\PowerWord\\Server\\files\\'

app = Flask(__name__)
api = Api(app)

class Log(Resource):

    def post (self):
        parser = reqparse.RequestParser()
        parser.add_argument("date")
        parser.add_argument("cname")
        parser.add_argument("log")

        args = parser.parse_args()

        print (args["date"], "=> From:" , args["cname"], "\nLog:", args["log"])


@app.route('/files/upload', methods=['GET', 'POST'])
def upload_file():
    
    if request.method == 'POST':
        filename = request.args["filename"]
        filedata = request.data
        file_full_path = UPLOAD_FOLDER + request.remote_addr + "\\"
        Path(file_full_path).mkdir(parents=True, exist_ok=True)
        open(file_full_path + filename, 'wb').write(filedata)
        return "gotit"
            

api.add_resource(Log, "/log/")
app.run(debug=True)