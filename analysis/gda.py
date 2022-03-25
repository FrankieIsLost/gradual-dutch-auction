from abc import ABC, abstractmethod
import math 

class DiscreteGDA(ABC): 
    
    @abstractmethod
    def get_cumulative_purchase_price(self, numTotalPurchases, timeSinceStart, quantity):
        pass
    
class ContinuousGDA(ABC): 
    
    @abstractmethod
    def get_cumulative_purchase_price(self, ageLastAvailableAuction, quantity):
        pass

class ExponentialDiscreteGDA(DiscreteGDA):
    
    def __init__(self, price_scale, decay_constant): 
        self.price_scale = price_scale
        self.decay_constant = decay_constant
        
    def get_cumulative_purchase_price(self, num_total_purchases, time_since_start, quantity):
        t1 = self.price_scale * math.exp(num_total_purchases - self.decay_constant * time_since_start)
        t2 = math.exp(quantity) - 1 
        t3 = math.e - 1 
        return t1 * t2 / t3
    
class ExponentialContinuousGDA(ContinuousGDA): 
    
    def __init__(self, price_scale, decay_constant, emission_rate): 
        self.price_scale = price_scale
        self.decay_constant = decay_constant
        self.emission_rate = emission_rate
        
    def get_cumulative_purchase_price(self, age_last_available_auction, quantity):
        t1 = self.price_scale / self.decay_constant
        t2 = math.exp(self.decay_constant * quantity / self.emission_rate) - 1 
        t3 = math.exp(self.decay_constant * age_last_available_auction)
        return t1 * t2 / t3
        
class UniswapEquivalentGDA(ContinuousGDA): 
    
    def __init__(self, price_scale): 
        self.price_scale = price_scale

    def get_cumulative_purchase_price(self, age_last_available_auction, quantity):
        t1 = self.price_scale / (age_last_available_auction - quantity)
        t2 = self.price_scale / age_last_available_auction
        return t1 - t2