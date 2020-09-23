from flask import Flask
from flask_restful import Api, Resource, reqparse

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

api.add_resource(Log, "/log/")
app.run(debug=True)