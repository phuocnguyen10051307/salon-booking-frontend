class StoreService {
  final String id;
  final String name;
  final String category;
  final double price;
  final int durationMinutes;
  final String imageUrl;

  StoreService({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMinutes,
    required this.imageUrl,
  });
}

class Store {
  final String id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<StoreService> services;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.services,
  });
}

final List<Store> mockStores = [
  Store(
    id: '1',
    name: 'Glamour Hair Studio',
    address: '123 Nguyen Trai, District 5, HCMC',
    rating: 4.8,
    reviewCount: 124,
    imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=600&q=80',
    services: [
      StoreService(id: 's1', name: 'Classic Haircut', category: 'Haircut', price: 15.0, durationMinutes: 30, imageUrl: ''),
      StoreService(id: 's2', name: 'Hair Coloring', category: 'Coloring', price: 50.0, durationMinutes: 90, imageUrl: ''),
      StoreService(id: 's3', name: 'Hair Wash & Styling', category: 'Haircut', price: 20.0, durationMinutes: 45, imageUrl: ''),
    ],
  ),
  Store(
    id: '2',
    name: 'Luxe Spa & Nails',
    address: '45 Le Loi, District 1, HCMC',
    rating: 4.9,
    reviewCount: 312,
    imageUrl: 'https://images.unsplash.com/photo-1522337660859-02fbefca4702?auto=format&fit=crop&w=600&q=80',
    services: [
      StoreService(id: 's4', name: 'Manicure & Pedicure', category: 'Nails', price: 30.0, durationMinutes: 60, imageUrl: ''),
      StoreService(id: 's5', name: 'Facial Treatment', category: 'Facial', price: 45.0, durationMinutes: 60, imageUrl: ''),
      StoreService(id: 's6', name: 'Full Body Massage', category: 'Massage', price: 60.0, durationMinutes: 90, imageUrl: ''),
    ],
  ),
  Store(
    id: '3',
    name: 'Glow Beauty Bar',
    address: '78 Tran Hung Dao, District 1, HCMC',
    rating: 4.6,
    reviewCount: 89,
    imageUrl: 'https://images.unsplash.com/photo-1595476108010-b4d1f10d5e43?auto=format&fit=crop&w=600&q=80',
    services: [
      StoreService(id: 's7', name: 'Bridal Makeup', category: 'Makeup', price: 100.0, durationMinutes: 120, imageUrl: ''),
      StoreService(id: 's8', name: 'Eyebrow Waxing', category: 'Waxing', price: 10.0, durationMinutes: 15, imageUrl: ''),
      StoreService(id: 's9', name: 'Aromatherapy Spa', category: 'Spa', price: 55.0, durationMinutes: 75, imageUrl: ''),
    ],
  ),
  Store(
    id: '4',
    name: 'Modern Men Barbershop',
    address: '12 Nguyen Thi Minh Khai, District 3, HCMC',
    rating: 4.7,
    reviewCount: 205,
    imageUrl: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=600&q=80',
    services: [
      StoreService(id: 's10', name: 'Men Haircut', category: 'Haircut', price: 12.0, durationMinutes: 30, imageUrl: ''),
      StoreService(id: 's11', name: 'Beard Trim', category: 'Haircut', price: 8.0, durationMinutes: 20, imageUrl: ''),
    ],
  ),
];
