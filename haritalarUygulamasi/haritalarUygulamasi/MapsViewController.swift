//
//  ViewController.swift
//  haritalarUygulamasi
//
//  Created by Dilan Öztürk on 20.12.2022.
//

import UIKit
import MapKit // ekranda haritayı göstermek için
import CoreLocation // kullanıcının konumunu alma
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var notTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""
    var secilenId : UUID?
    
    var locationManager = CLLocationManager() // konumla ilgili olayları ele almamızı sağlar
    
    var annotiationTitle = ""
    var annotiationSubtitle = ""
    var annotiationLatitude = Double()
    var annotiationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // kullanıcının tam olarak nerede olduğunu gösterir ama her zaman en iyi konumu algılamasına gerek yoktur bazen bir km ya da yüz metre çapına kadar göstermesini de isteyebiliriz çünkü tam konumu alması demek daha fazla pil vs harcaması anlamına gelir
        locationManager.requestWhenInUseAuthorization() // uygulama kullanılırken kullanıcıdan konum alma isteğinde bulunulur. daha sonra infodan gidip privacy - location when in use usage description ı seçerek konum alma sebebi kullanıcıya söylenir
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:))) // uzun süre aynı noktaya dokununca konum işaretleme
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsim != "" { // core data dan verileri çekme (ilk sayfada bir yer ismine tıklandığında detayları gösterecek) buradan sonra listviewcontroller a gidip didSelectRowAt ve prepare fonksiyonları açmak gerekiyor
            if let uuidString = secilenId?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.returnsObjectsAsFaults = false
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject]{
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotiationTitle = isim
                            }
                            if let not = sonuc.value(forKey: "not") as? String{
                                annotiationSubtitle = not
                            }
                            if let latitude = sonuc.value(forKey: "latitude") as? Double{
                                annotiationLatitude = latitude
                            }
                            if let longitude = sonuc.value(forKey: "longitude") as? Double{
                                annotiationLongitude = longitude
                            }
                            let annotiation = MKPointAnnotation() // pin oluşturma
                            annotiation.title = annotiationTitle // pin in üzerine title ı yazma
                            annotiation.subtitle = annotiationSubtitle // pin in üzerine subtitle ı yazma
                            let coordinate = CLLocationCoordinate2D(latitude: annotiationLatitude, longitude: annotiationLongitude) // pin ekleme
                            annotiation.coordinate = coordinate
                            
                            mapView.addAnnotation(annotiation)
                            isimTextField.text = annotiationTitle
                            notTextField.text = annotiationSubtitle
                            
                            locationManager.stopUpdatingLocation() // notu açınca güncel konumu göstermeyi durdurma
                            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // notu açınca nottaki konumun yakınına gitme
                            let region = MKCoordinateRegion(center: coordinate, span: span)
                            mapView.setRegion(region, animated: true)
                        }
                    }
                }catch{
                    print("hata")
                }
            }
        }else{
            
        }
    }
    
    @objc func konumSec (gestureRecognizer : UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began{
            
            let dokunulanNokta = gestureRecognizer.location(in: mapView) // mapview a dokunulacak
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView) // dokunulan noktayı koordinata dönüştürme
            
            secilenLatitude = dokunulanKoordinat.latitude // seçilen enlem ve boylamı bu fonksiyonun içinden bu şekilde alabiliyoruz
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation() // dokunulan noktaya not ekleme
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
        }
            
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { // her güncelleme olduğunda konumu ona göre güncelleme
       // print(locations[0].coordinate.latitude) konumu print etmeye gerek yok
       // print(locations[0].coordinate.longitude)
        if secilenIsim == "" { // sadece artıya tıklandığında konumu güncellemesini istiyoruz. bunu yapmazsak notlara tıklandığında bizi güncel konumumuza atar ve nottaki konuma gidemeyiz
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // kullanıcının enlem ve boylamını alma
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // sayıları ne kadar küçük yazarsak uygulama açıldığında konum o kadar yakında gözükecek
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func kaydetTiklandi(_ sender: Any) { // veri tabanına kaydetme
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context) // bu kodu oluşturabilmek için üste import coredata yazmak lazım
        yeniYer.setValue(isimTextField.text, forKey: "isim") // setvalue deyince değerleri kaydedebiliyoruz
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("kayıt edildi")
        } catch {
            print("hata var")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil) // kaydete bastıktan sonra kullanıcıyı listviewcontroller sayfasına atma
        navigationController?.popViewController(animated: true) // bunu da yazdıktan sonra listviewcontroller a gidip viewwillappear fonksiyonunu yazmak ge rekiyor
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? { // pin e tıklayınca i butonunun çıkması
        
        if annotation is MKUserLocation{ // eğer not kullanıcının güncel konumundaysa boş döndür
            return nil
        }
        let reuseId = "benimAnnotiation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) { // i butonuna tıklanınca neler olacağı
        
        if secilenIsim != "" { // eğer kayıtlı bir nota tıklandıysa
            
            var requestLocation = CLLocation(latitude: annotiationLatitude, longitude: annotiationLongitude) // istek konumum kayıtlı nottaki enlem ve boylamdır
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) {placemarkDizisi, hata in // parametrenin içinde sağdakinin üzerine tıklanacak
                
                if let placemarks = placemarkDizisi { // bu kod placemarkDizisi ni optional olmaktan çıkarıyor. placemarks optional değil.
                    if placemarks.count > 0 {
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0]) // placemarks dizimizden ilk elemanı al getir
                        let item = MKMapItem(placemark: yeniPlacemark) // üstteki işlemleri buradaki item ı alabilmek için yaptık
                        item.name = self.annotiationTitle // item, mevcut konumumuzdan gidilecek duraktır
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving] // ilk sırada arabayla gitme seçeneğini göster
                        
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
        }
    }
    

}

