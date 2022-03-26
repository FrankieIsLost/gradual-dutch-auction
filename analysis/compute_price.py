from gda import ExponentialDiscreteGDA, ExponentialContinuousGDA, UniswapEquivalentGDA
from eth_abi import encode_single
import argparse

def main(args): 
    if (args.type == 'exp_discrete'): 
        calculate_exp_discete(args)
    
def calculate_exp_discete(args):
    gda = ExponentialDiscreteGDA(args.price_scale / (10 ** 18), args.decay_constant / (10 ** 18))
    price = gda.get_cumulative_purchase_price(args.num_total_purchases, args.time_since_start, args.quantity)
    enc = encode_single('uint256', int(price))
    ## append 0x for FFI parsing 
    print("0x" + enc.hex())

def parse_args(): 
    parser = argparse.ArgumentParser()
    parser.add_argument("type")
    parser.add_argument("--price_scale", type=int)
    parser.add_argument("--decay_constant", type=int)
    parser.add_argument("--num_total_purchases", type=int)
    parser.add_argument("--time_since_start", type=int)
    parser.add_argument("--quantity", type=int)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args() 
    main(args)