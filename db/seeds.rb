ag = AgSession.create!(name: "AG 2026 - Association Exemple")

[ "Alice Dupont", "Bob Martin", "Claire Durand", "David Leroy" ].each do |name|
  ag.participants.create!(name: name)
end

q1 = ag.questions.create!(text: "Approbation du bilan financier 2025 ?", position: 1)
q1.choices.create!([
  { text: "Pour" },
  { text: "Contre" },
  { text: "Abstention" },
  { text: "Autre", is_other: true }
])

q2 = ag.questions.create!(text: "Renouvellement du bureau ?", position: 2)
q2.choices.create!([
  { text: "Pour" },
  { text: "Contre" },
  { text: "Abstention" }
])

puts "=== Session AG créée ==="
puts "Token de session : #{ag.token}"
puts ""
puts "Liens de vote :"
ag.participants.each do |p|
  puts "  #{p.name.ljust(20)} => /vote/#{ag.token}/#{p.token}"
end
puts ""
puts "Admin : http://localhost:3000/admin/login  (token: admin-secret)"
