# SimpleDrive's Managed Clients: companies, individuals and a main contractor, with sites and saved points.
with_company("SD") do
  def client(name, **attrs)
    Client.find_or_initialize_by(name:).tap { |c| c.update!(attrs) }
  end

  google = client("Google Asia Pacific", kind: :company, uen: "200817984R", contact_name: "Priya Raman",
                  phone: "+65 6521 8000", email: "transport@google.com", billing_address: "70 Pasir Panjang Road, #03-71 Mapletree Business City, Singapore 117371")
  [
    [ "Mapletree Business City", "70 Pasir Panjang Road, Singapore 117371", 1.2747, 103.7993 ],
    [ "Google Asia Pacific (Pasir Panjang)", "3 Pasir Panjang Road, Singapore 117438", 1.2768, 103.7952 ]
  ].each do |name, address, lat, lng|
    google.sites.find_or_initialize_by(name:).update!(address:, lat:, lng:)
  end
  google.pickup_points.find_or_initialize_by(name: "MBC Tower 1 Bus Bay").update!(
    address: "10 Pasir Panjang Road", postal_code: "117438", lat: 1.2752, lng: 103.7989, note: "Wait at the bus bay beside the taxi stand"
  )
  google.pickup_points.find_or_initialize_by(name: "Labrador Park MRT Exit A").update!(
    address: "Labrador Park MRT Station", postal_code: "119208", lat: 1.2722, lng: 103.8026, note: "Exit A, across the road from the bus stop"
  )

  client("DBS Bank", kind: :company, uen: "196800306E", contact_name: "Daniel Ng", phone: "+65 6878 8888",
                     email: "facilities@dbs.com", billing_address: "12 Marina Boulevard, DBS Asia Central, Singapore 018982")
  client("Marina Bay Sands", kind: :company, uen: "200505290K", contact_name: "Rebecca Chua", phone: "+65 6688 8888",
                             email: "events@marinabaysands.com", billing_address: "10 Bayfront Avenue, Singapore 018956")
  client("Tan Family", kind: :individual, contact_name: "Tan Wei Ming", phone: "+65 9123 4567", email: "weiming.tan@gmail.com",
                       billing_address: "Blk 123 Bedok North Street 2, #08-45, Singapore 460123")
  client("Dr Rachel Lim", kind: :individual, phone: "+65 9876 5432", email: "rachel.lim@gmail.com")

  eastern = client("Eastern Coaches", kind: :transport_company, uen: "199803456W", contact_name: "Mr Goh",
                                      phone: "+65 6345 6789", email: "ops@easterncoaches.sg")
  [ "Mapletree Investments", "Nanyang Polytechnic" ].each { |name| eastern.end_customers.find_or_create_by!(name:) }
end
