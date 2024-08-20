import datetime
import json
import pprint
from flask import Flask, render_template, request
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///db.sqlite'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Batcher(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    txid = db.Column(db.String(32))
    blocknumber = db.Column(db.Integer, index=True)
    blockhash = db.Column(db.String(32))
    timestamp = db.Column(db.String(64))

    def to_dict(self):
        return {
            'txid': self.txid,
            'blocknumber': self.blocknumber,
            'blockhash': self.blockhash,
            'timestamp': self.timestamp
        }

db.create_all()

# Dashboard
@app.route('/dashboard')
def index():
    return render_template('ajax_table.html', title='Optimism Batcher')


@app.route('/api/data')
def data():
    return {'data': [batch.to_dict() for batch in Batcher.query]}


# Posted data from op-batcher
@app.route('/', methods=['POST'])
def process_json():
    content_type = request.headers.get('Content-Type')
    batch=[]
    if (content_type == 'application/json'):
        batch = request.json
    else:
        #return 'Content-Type not supported!'
        raw=request.get_data(as_text=True)
        batch=json.loads(raw)
    
    blocksplit=batch["body"]["blockid"].split(":")

    entry = Batcher(
                    txid=batch["body"]["txid"],
                    blocknumber=blocksplit[1],
                    blockhash=blocksplit[0],
                    timestamp=datetime.datetime.now(datetime.timezone.utc).strftime("%m/%d/%Y, %H:%M:%S"))

    db.session.add(entry)
    db.session.commit()
    print("New batch added to database : ", json.dumps(batch, indent=4))
    
    return json.dumps({'success':True}), 200, {'ContentType':'application/json'} 

    #return json.dumps(r.json(), indent=4)
    return r.text

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9876)
