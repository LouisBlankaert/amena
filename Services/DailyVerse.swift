// DailyVerse : source unique des 100 versets bibliques utilisés pour le "verset du jour"
// Texte EXACT de la Bible, jamais reformulé : Louis Segond 1910 en français, King James
// en anglais (toutes deux dans le domaine public). Un extrait coupe le verset mais ne change
// aucun mot. Attention : dans les Psaumes, la Segond compte le titre comme verset 1, les
// numéros français sont donc souvent décalés d'un cran par rapport à l'anglais (c'est normal).
// Utilisé à la fois par l'onboarding (VerseOfDayView) et par la carte du même nom sur Home
import Foundation

enum DailyVerse {
    // Liste recalculée à chaque accès (pas "static let") pour refléter un changement
    // de langue en cours de session, comme le fait t() partout ailleurs dans l'app
    static var verses: [(text: String, reference: String)] {
        [
            (t("For I know the thoughts that I think toward you, saith the Lord, thoughts of peace, and not of evil, to give you an expected end.", "Car je connais les projets que j’ai formés sur vous, dit l’Éternel, projets de paix et non de malheur, afin de vous donner un avenir et de l’espérance."), t("Jeremiah 29:11", "Jérémie 29:11")),
            (t("Trust in the Lord with all thine heart; and lean not unto thine own understanding.", "Confie-toi en l’Éternel de tout ton cœur, Et ne t’appuie pas sur ta sagesse."), t("Proverbs 3:5", "Proverbes 3:5")),
            (t("I can do all things through Christ which strengtheneth me.", "Je puis tout par celui qui me fortifie."), t("Philippians 4:13", "Philippiens 4:13")),
            (t("The Lord is my shepherd; I shall not want.", "L’Éternel est mon berger : je ne manquerai de rien."), t("Psalm 23:1", "Psaume 23:1")),
            (t("Be still, and know that I am God.", "Arrêtez, et sachez que je suis Dieu."), t("Psalm 46:10", "Psaume 46:11")),
            (t("Come unto me, all ye that labour and are heavy laden, and I will give you rest.", "Venez à moi, vous tous qui êtes fatigués et chargés, et je vous donnerai du repos."), t("Matthew 11:28", "Matthieu 11:28")),
            (t("For God so loved the world, that he gave his only begotten Son.", "Car Dieu a tant aimé le monde qu’il a donné son Fils unique."), t("John 3:16", "Jean 3:16")),
            (t("The Lord is my light and my salvation; whom shall I fear?", "L’Éternel est ma lumière et mon salut : De qui aurais-je crainte ?"), t("Psalm 27:1", "Psaume 27:1")),
            (t("But they that wait upon the Lord shall renew their strength.", "Mais ceux qui se confient en l’Éternel renouvellent leur force."), t("Isaiah 40:31", "Ésaïe 40:31")),
            (t("Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.", "Ne vous inquiétez de rien ; mais en toute chose faites connaître vos besoins à Dieu par des prières et des supplications."), t("Philippians 4:6", "Philippiens 4:6")),
            (t("Thou shalt love the Lord thy God with all thy heart, and with all thy soul, and with all thy mind.", "Tu aimeras le Seigneur, ton Dieu, de tout ton cœur, de toute ton âme, et de toute ta pensée."), t("Matthew 22:37", "Matthieu 22:37")),
            (t("For by grace are ye saved through faith.", "Car c’est par la grâce que vous êtes sauvés, par le moyen de la foi."), t("Ephesians 2:8", "Éphésiens 2:8")),
            (t("The name of the Lord is a strong tower: the righteous runneth into it, and is safe.", "Le nom de l’Éternel est une tour forte ; Le juste s’y réfugie, et se trouve en sûreté."), t("Proverbs 18:10", "Proverbes 18:10")),
            (t("I will praise thee, O Lord, with my whole heart.", "Je louerai l’Éternel de tout mon cœur."), t("Psalm 9:1", "Psaume 9:2")),
            (t("Thy word is a lamp unto my feet, and a light unto my path.", "Ta parole est une lampe à mes pieds, Et une lumière sur mon sentier."), t("Psalm 119:105", "Psaume 119:105")),
            (t("Let every thing that hath breath praise the Lord.", "Que tout ce qui respire loue l’Éternel !"), t("Psalm 150:6", "Psaume 150:6")),
            (t("And we know that all things work together for good to them that love God.", "Nous savons, du reste, que toutes choses concourent au bien de ceux qui aiment Dieu."), t("Romans 8:28", "Romains 8:28")),
            (t("Casting all your care upon him; for he careth for you.", "Et déchargez-vous sur lui de tous vos soucis, car lui-même prend soin de vous."), t("1 Peter 5:7", "1 Pierre 5:7")),
            (t("But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.", "Cherchez premièrement le royaume et la justice de Dieu ; et toutes ces choses vous seront données par-dessus."), t("Matthew 6:33", "Matthieu 6:33")),
            (t("I am the way, the truth, and the life.", "Je suis le chemin, la vérité, et la vie."), t("John 14:6", "Jean 14:6")),
            (t("Create in me a clean heart, O God.", "Ô Dieu ! crée en moi un cœur pur."), t("Psalm 51:10", "Psaume 51:12")),
            (t("The Lord bless thee, and keep thee.", "Que l’Éternel te bénisse, et qu’il te garde !"), t("Numbers 6:24", "Nombres 6:24")),
            (t("Rejoice in the Lord alway: and again I say, Rejoice.", "Réjouissez-vous toujours dans le Seigneur ; je le répète, réjouissez-vous."), t("Philippians 4:4", "Philippiens 4:4")),
            (t("He restoreth my soul.", "Il restaure mon âme."), t("Psalm 23:3", "Psaume 23:3")),
            (t("Jesus Christ the same yesterday, and to day, and for ever.", "Jésus-Christ est le même hier, aujourd’hui, et éternellement."), t("Hebrews 13:8", "Hébreux 13:8")),
            (t("Ask, and it shall be given you; seek, and ye shall find.", "Demandez, et l’on vous donnera ; cherchez, et vous trouverez."), t("Matthew 7:7", "Matthieu 7:7")),
            (t("And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.", "Et la paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs et vos pensées en Jésus-Christ."), t("Philippians 4:7", "Philippiens 4:7")),
            (t("Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me.", "Quand je marche dans la vallée de l’ombre de la mort, Je ne crains aucun mal, car tu es avec moi."), t("Psalm 23:4", "Psaume 23:4")),
            (t("God is our refuge and strength, a very present help in trouble.", "Dieu est pour nous un refuge et un appui, Un secours qui ne manque jamais dans la détresse."), t("Psalm 46:1", "Psaume 46:2")),
            (t("For with God nothing shall be impossible.", "Car rien n’est impossible à Dieu."), t("Luke 1:37", "Luc 1:37")),
            (t("Be strong and of a good courage; be not afraid, neither be thou dismayed: for the Lord thy God is with thee whithersoever thou goest.", "Ne t’ai-je pas donné cet ordre : Fortifie-toi et prends courage ? Ne t’effraie point et ne t’épouvante point, car l’Éternel, ton Dieu, est avec toi dans tout ce que tu entreprendras."), t("Joshua 1:9", "Josué 1:9")),
            (t("Thou wilt shew me the path of life: in thy presence is fulness of joy.", "Tu me feras connaître le sentier de la vie ; Il y a d’abondantes joies devant ta face."), t("Psalm 16:11", "Psaume 16:11")),
            (t("Let the words of my mouth, and the meditation of my heart, be acceptable in thy sight, O Lord.", "Reçois favorablement les paroles de ma bouche Et les sentiments de mon cœur, Ô Éternel."), t("Psalm 19:14", "Psaume 19:15")),
            (t("Shew me thy ways, O Lord; teach me thy paths.", "Éternel ! fais-moi connaître tes voies, Enseigne-moi tes sentiers."), t("Psalm 25:4", "Psaume 25:4")),
            (t("I will instruct thee and teach thee in the way which thou shalt go: I will guide thee with mine eye.", "Je t’instruirai et te montrerai la voie que tu dois suivre ; Je te conseillerai, j’aurai le regard sur toi."), t("Psalm 32:8", "Psaume 32:8")),
            (t("O taste and see that the Lord is good: blessed is the man that trusteth in him.", "Sentez et voyez combien l’Éternel est bon ! Heureux l’homme qui cherche en lui son refuge !"), t("Psalm 34:8", "Psaume 34:9")),
            (t("The Lord is nigh unto them that are of a broken heart; and saveth such as be of a contrite spirit.", "L’Éternel est près de ceux qui ont le cœur brisé, Et il sauve ceux qui ont l’esprit dans l’abattement."), t("Psalm 34:18", "Psaume 34:19")),
            (t("Delight thyself also in the Lord; and he shall give thee the desires of thine heart.", "Fais de l’Éternel tes délices, Et il te donnera ce que ton cœur désire."), t("Psalm 37:4", "Psaume 37:4")),
            (t("As the hart panteth after the water brooks, so panteth my soul after thee, O God.", "Comme une biche soupire après des courants d’eau, Ainsi mon âme soupire après toi, ô Dieu !"), t("Psalm 42:1", "Psaume 42:2")),
            (t("Cast thy burden upon the Lord, and he shall sustain thee: he shall never suffer the righteous to be moved.", "Remets ton sort à l’Éternel, et il te soutiendra, Il ne laissera jamais chanceler le juste."), t("Psalm 55:22", "Psaume 55:23")),
            (t("Truly my soul waiteth upon God: from him cometh my salvation.", "Oui, c’est en Dieu que mon âme se confie ; De lui vient mon salut."), t("Psalm 62:1", "Psaume 62:2")),
            (t("He that dwelleth in the secret place of the most High shall abide under the shadow of the Almighty.", "Celui qui demeure sous l’abri du Très-Haut Repose à l’ombre du Tout Puissant."), t("Psalm 91:1", "Psaume 91:1")),
            (t("For the Lord is good; his mercy is everlasting; and his truth endureth to all generations.", "Car l’Éternel est bon ; sa bonté dure toujours, Et sa fidélité de génération en génération."), t("Psalm 100:5", "Psaume 100:5")),
            (t("Bless the Lord, O my soul, and forget not all his benefits.", "Mon âme, bénis l’Éternel, Et n’oublie aucun de ses bienfaits !"), t("Psalm 103:2", "Psaume 103:2")),
            (t("This is the day which the Lord hath made; we will rejoice and be glad in it.", "C’est ici la journée que l’Éternel a faite : Qu’elle soit pour nous un sujet d’allégresse et de joie !"), t("Psalm 118:24", "Psaume 118:24")),
            (t("I will lift up mine eyes unto the hills, from whence cometh my help.", "Je lève mes yeux vers les montagnes… D’où me viendra le secours ?"), t("Psalm 121:1", "Psaume 121:1")),
            (t("I will praise thee; for I am fearfully and wonderfully made: marvellous are thy works.", "Je te loue de ce que je suis une créature si merveilleuse. Tes œuvres sont admirables."), t("Psalm 139:14", "Psaume 139:14")),
            (t("Cause me to hear thy lovingkindness in the morning; for in thee do I trust.", "Fais-moi dès le matin entendre ta bonté ! Car je me confie en toi."), t("Psalm 143:8", "Psaume 143:8")),
            (t("The Lord is nigh unto all them that call upon him, to all that call upon him in truth.", "L’Éternel est près de tous ceux qui l’invoquent, De tous ceux qui l’invoquent avec sincérité."), t("Psalm 145:18", "Psaume 145:18")),
            (t("Commit thy works unto the Lord, and thy thoughts shall be established.", "Recommande à l’Éternel tes œuvres, Et tes projets réussiront."), t("Proverbs 16:3", "Proverbes 16:3")),
            (t("A man’s heart deviseth his way: but the Lord directeth his steps.", "Le cœur de l’homme médite sa voie, Mais c’est l’Éternel qui dirige ses pas."), t("Proverbs 16:9", "Proverbes 16:9")),
            (t("A merry heart doeth good like a medicine: but a broken spirit drieth the bones.", "Un cœur joyeux est un bon remède, Mais un esprit abattu dessèche les os."), t("Proverbs 17:22", "Proverbes 17:22")),
            (t("There are many devices in a man’s heart; nevertheless the counsel of the Lord, that shall stand.", "Il y a dans le cœur de l’homme beaucoup de projets, Mais c’est le dessein de l’Éternel qui s’accomplit."), t("Proverbs 19:21", "Proverbes 19:21")),
            (t("Thou wilt keep him in perfect peace, whose mind is stayed on thee: because he trusteth in thee.", "À celui qui est ferme dans ses sentiments Tu assures la paix, la paix, Parce qu’il se confie en toi."), t("Isaiah 26:3", "Ésaïe 26:3")),
            (t("Fear thou not; for I am with thee: be not dismayed; for I am thy God.", "Ne crains rien, car je suis avec toi ; Ne promène pas des regards inquiets, car je suis ton Dieu."), t("Isaiah 41:10", "Ésaïe 41:10")),
            (t("When thou passest through the waters, I will be with thee; and through the rivers, they shall not overflow thee.", "Si tu traverses les eaux, je serai avec toi ; Et les fleuves, ils ne te submergeront point."), t("Isaiah 43:2", "Ésaïe 43:2")),
            (t("It is of the Lord’s mercies that we are not consumed, because his compassions fail not. They are new every morning: great is thy faithfulness.", "Les bontés de l’Éternel ne sont pas épuisées, Ses compassions ne sont pas à leur terme ; Elles se renouvellent chaque matin. Oh ! que ta fidélité est grande !"), t("Lamentations 3:22-23", "Lamentations 3:22-23")),
            (t("What doth the Lord require of thee, but to do justly, and to love mercy, and to walk humbly with thy God?", "C’est que tu pratiques la justice, Que tu aimes la miséricorde, Et que tu marches humblement avec ton Dieu."), t("Micah 6:8", "Michée 6:8")),
            (t("The Lord thy God in the midst of thee is mighty; he will save, he will rejoice over thee with joy.", "L’Éternel, ton Dieu, est au milieu de toi, comme un héros qui sauve ; Il fera de toi sa plus grande joie."), t("Zephaniah 3:17", "Sophonie 3:17")),
            (t("Ye are the light of the world. A city that is set on an hill cannot be hid.", "Vous êtes la lumière du monde. Une ville située sur une montagne ne peut être cachée."), t("Matthew 5:14", "Matthieu 5:14")),
            (t("Take therefore no thought for the morrow: for the morrow shall take thought for the things of itself.", "Ne vous inquiétez donc pas du lendemain ; car le lendemain aura soin de lui-même."), t("Matthew 6:34", "Matthieu 6:34")),
            (t("Take my yoke upon you, and learn of me; for I am meek and lowly in heart: and ye shall find rest unto your souls.", "Prenez mon joug sur vous et recevez mes instructions, car je suis doux et humble de cœur ; et vous trouverez du repos pour vos âmes."), t("Matthew 11:29", "Matthieu 11:29")),
            (t("And, lo, I am with you alway, even unto the end of the world. Amen.", "Et voici, je suis avec vous tous les jours, jusqu’à la fin du monde."), t("Matthew 28:20", "Matthieu 28:20")),
            (t("What things soever ye desire, when ye pray, believe that ye receive them, and ye shall have them.", "Tout ce que vous demanderez en priant, croyez que vous l’avez reçu, et vous le verrez s’accomplir."), t("Mark 11:24", "Marc 11:24")),
            (t("Give, and it shall be given unto you; good measure, pressed down, and shaken together, and running over, shall men give into your bosom.", "Donnez, et il vous sera donné : on versera dans votre sein une bonne mesure, serrée, secouée et qui déborde."), t("Luke 6:38", "Luc 6:38")),
            (t("I am the light of the world: he that followeth me shall not walk in darkness, but shall have the light of life.", "Je suis la lumière du monde ; celui qui me suit ne marchera pas dans les ténèbres, mais il aura la lumière de la vie."), t("John 8:12", "Jean 8:12")),
            (t("I am come that they might have life, and that they might have it more abundantly.", "Je suis venu afin que les brebis aient la vie, et qu’elles soient dans l’abondance."), t("John 10:10", "Jean 10:10")),
            (t("A new commandment I give unto you, That ye love one another; as I have loved you, that ye also love one another.", "Je vous donne un commandement nouveau : Aimez-vous les uns les autres ; comme je vous ai aimés, vous aussi, aimez-vous les uns les autres."), t("John 13:34", "Jean 13:34")),
            (t("I am the vine, ye are the branches: He that abideth in me, and I in him, the same bringeth forth much fruit: for without me ye can do nothing.", "Je suis le cep, vous êtes les sarments. Celui qui demeure en moi et en qui je demeure porte beaucoup de fruit, car sans moi vous ne pouvez rien faire."), t("John 15:5", "Jean 15:5")),
            (t("In the world ye shall have tribulation: but be of good cheer; I have overcome the world.", "Vous aurez des tribulations dans le monde ; mais prenez courage, j’ai vaincu le monde."), t("John 16:33", "Jean 16:33")),
            (t("But God commendeth his love toward us, in that, while we were yet sinners, Christ died for us.", "Mais Dieu prouve son amour envers nous, en ce que, lorsque nous étions encore des pécheurs, Christ est mort pour nous."), t("Romans 5:8", "Romains 5:8")),
            (t("If God be for us, who can be against us?", "Si Dieu est pour nous, qui sera contre nous ?"), t("Romans 8:31", "Romains 8:31")),
            (t("Rejoicing in hope; patient in tribulation; continuing instant in prayer.", "Réjouissez-vous en espérance. Soyez patients dans l’affliction. Persévérez dans la prière."), t("Romans 12:12", "Romains 12:12")),
            (t("Now the God of hope fill you with all joy and peace in believing.", "Que le Dieu de l’espérance vous remplisse de toute joie et de toute paix dans la foi."), t("Romans 15:13", "Romains 15:13")),
            (t("Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself.", "La charité est patiente, elle est pleine de bonté ; la charité n’est point envieuse ; la charité ne se vante point."), t("1 Corinthians 13:4", "1 Corinthiens 13:4")),
            (t("And now abideth faith, hope, charity, these three; but the greatest of these is charity.", "Maintenant donc ces trois choses demeurent : la foi, l’espérance, la charité ; mais la plus grande de ces choses, c’est la charité."), t("1 Corinthians 13:13", "1 Corinthiens 13:13")),
            (t("Therefore if any man be in Christ, he is a new creature: old things are passed away; behold, all things are become new.", "Si quelqu’un est en Christ, il est une nouvelle créature. Les choses anciennes sont passées ; voici, toutes choses sont devenues nouvelles."), t("2 Corinthians 5:17", "2 Corinthiens 5:17")),
            (t("So let him give; not grudgingly, or of necessity: for God loveth a cheerful giver.", "Que chacun donne comme il l’a résolu en son cœur, sans tristesse ni contrainte ; car Dieu aime celui qui donne avec joie."), t("2 Corinthians 9:7", "2 Corinthiens 9:7")),
            (t("My grace is sufficient for thee: for my strength is made perfect in weakness.", "Ma grâce te suffit, car ma puissance s’accomplit dans la faiblesse."), t("2 Corinthians 12:9", "2 Corinthiens 12:9")),
            (t("But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith, meekness, temperance.", "Mais le fruit de l’Esprit, c’est l’amour, la joie, la paix, la patience, la bonté, la bénignité, la fidélité, la douceur, la tempérance."), t("Galatians 5:22-23", "Galates 5:22-23")),
            (t("And let us not be weary in well doing: for in due season we shall reap, if we faint not.", "Ne nous lassons pas de faire le bien ; car nous moissonnerons au temps convenable, si nous ne nous relâchons pas."), t("Galatians 6:9", "Galates 6:9")),
            (t("Now unto him that is able to do exceeding abundantly above all that we ask or think.", "Or, à celui qui peut faire, par la puissance qui agit en nous, infiniment au delà de tout ce que nous demandons ou pensons."), t("Ephesians 3:20", "Éphésiens 3:20")),
            (t("And be ye kind one to another, tenderhearted, forgiving one another, even as God for Christ’s sake hath forgiven you.", "Soyez bons les uns envers les autres, compatissants, vous pardonnant réciproquement, comme Dieu vous a pardonné en Christ."), t("Ephesians 4:32", "Éphésiens 4:32")),
            (t("Being confident of this very thing, that he which hath begun a good work in you will perform it until the day of Jesus Christ.", "Je suis persuadé que celui qui a commencé en vous cette bonne œuvre la rendra parfaite pour le jour de Jésus-Christ."), t("Philippians 1:6", "Philippiens 1:6")),
            (t("Whatsoever things are true, whatsoever things are honest, whatsoever things are just, whatsoever things are pure, whatsoever things are lovely, whatsoever things are of good report; if there be any virtue, and if there be any praise, think on these things.", "Que tout ce qui est vrai, tout ce qui est honorable, tout ce qui est juste, tout ce qui est pur, tout ce qui est aimable, tout ce qui mérite l’approbation, ce qui est vertueux et digne de louange, soit l’objet de vos pensées."), t("Philippians 4:8", "Philippiens 4:8")),
            (t("And let the peace of God rule in your hearts, to the which also ye are called in one body; and be ye thankful.", "Et que la paix de Christ, à laquelle vous avez été appelés pour former un seul corps, règne dans vos cœurs."), t("Colossians 3:15", "Colossiens 3:15")),
            (t("Rejoice evermore. Pray without ceasing. In every thing give thanks.", "Soyez toujours joyeux. Priez sans cesse. Rendez grâces en toutes choses."), t("1 Thessalonians 5:16-18", "1 Thessaloniciens 5:16-18")),
            (t("Now faith is the substance of things hoped for, the evidence of things not seen.", "Or la foi est une ferme assurance des choses qu’on espère, une démonstration de celles qu’on ne voit pas."), t("Hebrews 11:1", "Hébreux 11:1")),
            (t("And let us run with patience the race that is set before us.", "Et courons avec persévérance dans la carrière qui nous est ouverte."), t("Hebrews 12:1", "Hébreux 12:1")),
            (t("I will never leave thee, nor forsake thee.", "Je ne te délaisserai point, et je ne t’abandonnerai point."), t("Hebrews 13:5", "Hébreux 13:5")),
            (t("If any of you lack wisdom, let him ask of God, that giveth to all men liberally.", "Si quelqu’un d’entre vous manque de sagesse, qu’il la demande à Dieu, qui donne à tous simplement et sans reproche."), t("James 1:5", "Jacques 1:5")),
            (t("Draw nigh to God, and he will draw nigh to you.", "Approchez-vous de Dieu, et il s’approchera de vous."), t("James 4:8", "Jacques 4:8")),
            (t("If we confess our sins, he is faithful and just to forgive us our sins.", "Si nous confessons nos péchés, il est fidèle et juste pour nous les pardonner."), t("1 John 1:9", "1 Jean 1:9")),
            (t("There is no fear in love; but perfect love casteth out fear.", "La crainte n’est pas dans l’amour, mais l’amour parfait bannit la crainte."), t("1 John 4:18", "1 Jean 4:18")),
            (t("We love him, because he first loved us.", "Pour nous, nous l’aimons, parce qu’il nous a aimés le premier."), t("1 John 4:19", "1 Jean 4:19")),
            (t("I stand at the door, and knock: if any man hear my voice, and open the door, I will come in to him.", "Voici, je me tiens à la porte, et je frappe. Si quelqu’un entend ma voix et ouvre la porte, j’entrerai chez lui."), t("Revelation 3:20", "Apocalypse 3:20")),
            (t("In the beginning God created the heaven and the earth.", "Au commencement, Dieu créa les cieux et la terre."), t("Genesis 1:1", "Genèse 1:1")),
            (t("The Lord shall fight for you, and ye shall hold your peace.", "L’Éternel combattra pour vous ; et vous, gardez le silence."), t("Exodus 14:14", "Exode 14:14")),
            (t("But as for me and my house, we will serve the Lord.", "Moi et ma maison, nous servirons l’Éternel."), t("Joshua 24:15", "Josué 24:15")),
            (t("If my people, which are called by my name, shall humble themselves, and pray, and seek my face.", "Si mon peuple sur qui est invoqué mon nom s’humilie, prie, et cherche ma face."), t("2 Chronicles 7:14", "2 Chroniques 7:14"))
        ]
    }

    // Verset du jour : un par jour de l'année, boucle tous les 100 jours
    static var today: (text: String, reference: String) {
        verse(for: Date())
    }

    // Verset d'un jour donné — sert aussi à la notification de 10h, pour que la notif
    // montre exactement le même verset que la carte sur Home ce jour-là
    static func verse(for date: Date) -> (text: String, reference: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let list = verses
        return list[dayOfYear % list.count]
    }
}
