class CrewMember {
  const CrewMember({
    required this.id,
    required this.name,
    required this.status,
  });
  final int id;
  final String name, status;
  factory CrewMember.fromJson(Map<String, dynamic> j) => CrewMember(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    status: j['status'] as String,
  );
}

class Crew {
  const Crew({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.members,
  });
  final int id, leaderId;
  final String name;
  final List<CrewMember> members;
  factory Crew.fromJson(Map<String, dynamic> j) => Crew(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    leaderId: (j['leaderId'] as num).toInt(),
    members: (j['members'] as List)
        .map((e) => CrewMember.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
