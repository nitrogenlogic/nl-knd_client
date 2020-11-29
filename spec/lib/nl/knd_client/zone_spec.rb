RSpec.describe(NL::KndClient::Zone) do
  let!(:full_lines) {
    [
      'xmin=-273 ymin=831 zmin=2660 xmax273 ymax=1036 zmax3108 px_xmin=259 px_ymin=6 px_zmin=960 px_xmax=381 px_ymax=80 px_zmax=979 occupied=0 pop=0 maxpop=9028 xc=0 yc=0 zc=0 sa=0 name="Projector"',
      'xmin1625 ymin136 zmin=4662 xmax1868 ymax797 zmax=4970 px_xmin79 px_ymin=138 px_zmin=1017 px_xmax=124 px_ymax=224 px_zmax=1022 occupied=1 pop=668 maxpop=3870 xc=1665 yc439 zc=4915 sa4456 name="Office_Door"',
      'xmin=-1594 ymin285 zmin=840 xmax=1533 ymax335 zmax=4032 px_xmin=0 px_ymin=0 px_zmin=678 px_xmax=639 px_ymax=198 px_zmax=1005 occupied=0 pop=0 maxpop=126522 xc=0 yc=0 zc=0 sa=0 name="Theater"',
      'xmin=-1199 ymin346 zmin=3780 xmax896 ymax=710 zmax=5138 px_xmin=178 px_ymin=127 px_zmin=1000 px_xmax=510 px_ymax=200 px_zmax=1024 occupied=0 pop=0 maxpop=24236 xc=0 yc=0 zc=0 sa=0 name="Theater2"',
      'xmin=-394 ymin=-170 zmin=5124 xmax668 ymax=706 zmax=5936 px_xmin=242 px_ymin=158 px_zmin=1024 px_xmax=366 px_ymax=259 px_zmax=1033 occupied=0 pop=0 maxpop=12524 xc=0 yc=0 zc=0 sa=0 name="Theater3"',
      'xmin364 ymin=-478 zmin=5852 xmax1108 ymax797 zmax=6342 px_xmin207 px_ymin=159 px_zmin=1032 px_xmax=286 px_ymax=289 px_zmax=1037 occupied=0 pop=76 maxpop=10270 xc=833 yc=49 zc=5876 sa7246 name="Stairs"',
      'xmin=-440 ymin=-467 zmin=5824 xmax182 ymax=694 zmax=6832 px_xmin=302 px_ymin=169 px_zmin=1032 px_xmax=365 px_ymax=288 px_zmax=1041 occupied=0 pop=0 maxpop=7497 xc=0 yc=0 zc=0 sa=0 name="Laundry"',
      'xmin=-1807 ymin=-398 zmin=3430 xmax=-1564 ymax=-11 zmax=3710 px_xmin=573 px_ymin=241 px_zmin=990 px_xmax=637 px_ymax=309 px_zmax=998 occupied=0 pop=0 maxpop=4352 xc=0 yc=0 zc=0 sa=0 name="Touchscreen"',
      'xmin1609 ymin273 zmin=3290 xmax1716 ymax649 zmax=3668 px_xmin=7 px_ymin=122 px_zmin=986 px_xmax=57 px_ymax=196 px_zmax=997 occupied=0 pop=0 maxpop=3700 xc=0 yc=0 zc=0 sa=0 name="Theater_Bright"',
      'xmin=-629 ymin=411 zmin=3905 xmax=-447 ymax=519 zmax=4339 px_xmin=381 px_ymin=161 px_zmin=1003 px_xmax=416 px_ymax=183 px_zmax=1012 occupied=0 pop=0 maxpop=770 xc=0 yc=0 zc=0 sa=0 name="Lightbright"',
    ]
  }

  let!(:partial_lines) {
    [
      'occupied=1 pop=668 maxpop=3870 xc=1666 yc=447 zc=4914 sa=4454 name="Office_Door"',
      'occupied=0 pop=76 maxpop=10270 xc=840 yc=220 zc=5893 sa=7288 name="Stairs"',
      'occupied=1 pop=688 maxpop=3870 xc=1665 yc=440 zc=4911 sa=4582 name="Office_Door"',
      'occupied=0 pop=60 maxpop=10270 xc=835 yc=210 zc=5861 sa=5690 name="Stairs"',
      'occupied=1 pop=608 maxpop=3870 xc=1663 yc=423 zc=4909 sa=4045 name="Office_Door"',
      'occupied=1 pop=552 maxpop=3870 xc=1666 yc=401 zc=4915 sa=3682 name="Office_Door"',
      'occupied=0 pop=32 maxpop=10270 xc=838 yc=243 zc=5861 sa=3034 name="Stairs"',
      'occupied=1 pop=684 maxpop=3870 xc=1662 yc=433 zc=4905 sa=4543 name="Office_Door"',
      'occupied=0 pop=4 maxpop=12524 xc=206 yc=-34 zc=5170 sa=2951 name="Theater3"',
      'occupied=0 pop=60 maxpop=10270 xc=836 yc=261 zc=5861 sa=5690 name="Stairs"',
      'occupied=1 pop=608 maxpop=3870 xc=1667 yc=408 zc=4909 sa=4046 name="Office_Door"',
      'occupied=0 pop=0 maxpop=12524 xc=0 yc=0 zc=0 sa=e+00 name="Theater3"',
      'occupied=0 pop=44 maxpop=10270 xc=838 yc=223 zc=5861 sa=4172 name="Stairs"',
      'occupied=1 pop=596 maxpop=3870 xc=1663 yc=414 zc=4904 sa=3957 name="Office_Door"',
      'occupied=0 pop=4 maxpop=12524 xc=206 yc=-34 zc=5170 sa=2951 name="Theater3"',
    ]
  }

  let!(:zone_hashes) {
    [
      {"xmin"=>-273, "ymin"=>831, "zmin"=>266, "xmax"=>273, "ymax"=>1036, "zmax"=>3108, "px_xmin"=>259, "px_ymin"=>6, "px_zmin"=>960, "px_xmax"=>381, "px_ymax"=>80, "px_zmax"=>979, "occupied"=>false, "pop"=>0, "maxpop"=>9028, "xc"=>0, "yc"=>0, "zc"=>0, "sa"=>0, "name"=>"Projector"},
      {"xmin"=>-1273, "ymin"=>1831, "zmin"=>266, "xmax"=>273, "ymax"=>1036, "zmax"=>3108, "px_xmin"=>259, "px_ymin"=>6, "px_zmin"=>960, "px_xmax"=>381, "px_ymax"=>80, "px_zmax"=>979, "occupied"=>false, "pop"=>0, "maxpop"=>9028, "xc"=>0, "yc"=>0, "zc"=>0, "sa"=>0, "name"=>"Projector2"},
    ]
  }

  describe '#initialize' do
    it 'can parse full key-value zone lines' do
      parsed = full_lines.map { |l| NL::KndClient::Zone.new(l) }
      names = parsed.map { |z| z['name'] }.sort.uniq
      expect(names).to eq(
        [
          'Projector',
          'Office_Door',
          'Theater',
          'Theater2',
          'Theater3',
          'Stairs',
          'Laundry',
          'Touchscreen',
          'Theater_Bright',
          'Lightbright',
        ].sort
      )
    end

    it 'can parse partial key-value zone lines' do
      parsed = partial_lines.map { |l| NL::KndClient::Zone.new(l) }
      names = parsed.map { |z| z['name'] }.sort.uniq
      expect(names).to eq(
        [
          'Office_Door',
          'Stairs',
          'Theater3',
        ]
      )
    end

    it 'can create zones from hashes' do
      parsed = zone_hashes.map { |h| NL::KndClient::Zone.new(h) }
      names = parsed.map { |z| z['name'] }.sort.uniq
      expect(names).to eq(
        [
          'Projector',
          'Projector2',
        ]
      )
    end
  end
end
