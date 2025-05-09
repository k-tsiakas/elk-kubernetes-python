from flask import Flask, render_template, jsonify
import requests
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Define coins to track
COINS = ['BTCUSDT', 'ETHUSDT', 'ADAUSDT']
LOGO_URLS = {
    'BTC': 'https://assets.trustwalletapp.com/blockchains/binance/assets/BTCB-1DE/logo.png',
    'ETH': 'https://assets.trustwalletapp.com/blockchains/ethereum/info/logo.png',
    'ADA': 'https://assets.trustwalletapp.com/blockchains/cardano/info/logo.png',
    # Add more coins as needed
}

def get_prices():
    url = "https://api.bybit.com/v5/market/tickers"
    params = {"category": "spot"}
    response = requests.get(url, params=params)
    data = response.json()
    
    prices = {}
    if data['retCode'] == 0:
        for item in data['result']['list']:
            if item['symbol'] in COINS:
                prices[item['symbol']] = float(item['lastPrice'])
    app.logger.info(prices)
    return prices

@app.route('/')
def index():
    prices = get_prices()
    return render_template('index.html', prices=prices, logos=LOGO_URLS)

@app.route('/prices')
def prices():
    return jsonify(get_prices())

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
