from gda import ExponentialDiscreteGDA, ExponentialContinuousGDA, UniswapEquivalentGDA
from eth_abi import encode_single
import argparse

def main(args): 
    if (args.type == 'exp_discrete'): 
        calculate_exp_discete(args)
    
def calculate_exp_discete(args):
    enc = encode_single('uint256', 1000)
    print(enc.hex())

def parse_args(): 
    parser = argparse.ArgumentParser()
    parser.add_argument("type")
    parser.add_argument("--price_scale")
    parser.add_argument("--decay_constant")
    parser.add_argument("--num_total_purchases")
    parser.add_argument("--time_since_start")
    parser.add_argument("--quantity")
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args() 
    main(args)