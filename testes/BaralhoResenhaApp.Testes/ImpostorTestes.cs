using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Impostor: todo mundo recebe a mesma palavra no celular, menos um, que só
/// sabe o tema. Cada um fala uma pista em voz alta, na ordem da carta, e a
/// turma vota em quem é o impostor. Pegaram: o impostor leva o ponto;
/// erraram: leva quem votou errado.
/// </summary>
public sealed class ImpostorTestes
{
    private static readonly Carta Pizza = new("im-1", ModoDeJogo.Impostor, NivelDaCarta.Leve, "Pizza", Categoria: "Comida");

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Impostor => Todos.Single(j => j.Id == Sala.Rodada!.Impostor);
        public List<Jogador> Turma => Todos.Where(j => j.Id != Sala.Rodada!.Impostor).ToList();
        public int Rodada => Sala.Rodada!.Numero;
    }

    private static Mesa Montar(bool cartasNaManga = false)
    {
        var sala = new Sala("ABCD", new Baralho([Pizza]), new Random(3));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Impostor], true,
            Ritmo: RitmoDaBebida.Raiz, CartasNaManga: cartasNaManga));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    /// <summary>Cada um vota em quem a função escolher.</summary>
    private static void Votar(Mesa mesa, Func<Jogador, Jogador> emQuem)
    {
        foreach (var jogador in mesa.Todos) mesa.Sala.Responder(jogador.Token, mesa.Rodada, emQuem(jogador).Id.ToString());
    }

    [Fact]
    public void SoOImpostorNaoRecebeAPalavra()
    {
        var mesa = Montar();

        var doImpostor = mesa.Sala.Visao(mesa.Impostor.Token).Rodada!;
        Assert.True(doImpostor.SouImpostor);
        Assert.Equal("🕵️ Você é o impostor!", doImpostor.Texto);
        Assert.Equal("Tema: Comida", doImpostor.Dica);
        foreach (var jogador in mesa.Turma)
        {
            var visao = mesa.Sala.Visao(jogador.Token).Rodada!;
            Assert.False(visao.SouImpostor);
            Assert.Equal("Pizza", visao.Texto);
            Assert.Equal("Tema: Comida", visao.Dica);
        }
    }

    [Fact]
    public void NinguemSabeQuemEhOImpostorAntesDaRevelacao()
    {
        var mesa = Montar();

        foreach (var jogador in mesa.Todos)
        {
            var rodada = mesa.Sala.Visao(jogador.Token).Rodada!;
            Assert.Null(rodada.Alvo);
            Assert.Null(rodada.Revelacao);
        }
    }

    [Fact]
    public void AOrdemDasPistasTemTodoMundoENaoComecaPeloImpostor()
    {
        for (var semente = 0; semente < 20; semente++)
        {
            var sala = new Sala("ABCD", new Baralho([Pizza]), new Random(semente));
            var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
            sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Impostor], true));
            sala.Comecar(todos[0].Token);

            var fila = sala.Visao(todos[0].Token).Rodada!.Fila;
            Assert.Equal(todos.Select(j => j.Id).Order(), fila.Order());
            Assert.NotEqual(sala.Rodada!.Impostor, fila[0]);
        }
    }

    [Fact]
    public void NaoValeVotarEmSiMesmo()
    {
        var mesa = Montar();
        var ana = mesa.Todos[0];

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(ana.Token, mesa.Rodada, ana.Id.ToString()));

        Assert.Equal("Não vale votar em você.", erro.Message);
    }

    [Fact]
    public void TurmaPegouOImpostorEleLevaOPonto()
    {
        var mesa = Montar();
        var impostor = mesa.Impostor;
        Votar(mesa, jogador => jogador == impostor ? mesa.Turma[0] : impostor);

        var revelacao = mesa.Sala.Visao(mesa.Todos[0].Token).Rodada!.Revelacao!;
        Assert.Equal(impostor.Id, revelacao.Impostor);
        Assert.True(revelacao.Pegaram);
        Assert.Equal([impostor.Id], revelacao.Perderam);
        Assert.Equal(1, impostor.Pontos);
        Assert.All(mesa.Turma, j => Assert.Equal(0, j.Pontos));
    }

    [Fact]
    public void TurmaErrouLevaQuemVotouErradoEOImpostorGanhaCarta()
    {
        var mesa = Montar(cartasNaManga: true);
        var impostor = mesa.Impostor;
        var inocente = mesa.Turma[0];
        var maoAntes = impostor.Mao.Count;
        // Todo mundo (menos o inocente) vota no inocente; o inocente vota no impostor.
        Votar(mesa, jogador => jogador == inocente ? impostor : inocente);

        var revelacao = mesa.Sala.Visao(mesa.Todos[0].Token).Rodada!.Revelacao!;
        Assert.False(revelacao.Pegaram);
        Assert.Equal(mesa.Turma.Skip(1).Select(j => j.Id).Order(), revelacao.Perderam.Order());
        Assert.Equal(0, impostor.Pontos);
        Assert.Equal(0, inocente.Pontos);
        Assert.Equal(maoAntes + 1, impostor.Mao.Count);
        Assert.Equal(1, impostor.Estatisticas.Disfarces);
    }

    [Fact]
    public void EmpateComOImpostorNoTopoEleEscapa()
    {
        var mesa = Montar();
        var impostor = mesa.Impostor;
        var (a, b, c) = (mesa.Turma[0], mesa.Turma[1], mesa.Turma[2]);
        // Dois votos no impostor, dois no A.
        var votos = new Dictionary<Jogador, Jogador> { [impostor] = a, [a] = impostor, [b] = impostor, [c] = a };
        Votar(mesa, jogador => votos[jogador]);

        var revelacao = mesa.Sala.Visao(a.Token).Rodada!.Revelacao!;
        Assert.False(revelacao.Pegaram);
        Assert.Equal([c.Id], revelacao.Perderam);
    }

    [Fact]
    public void MestreDoDisfarceNosPremios()
    {
        var mesa = Montar();
        var inocente = mesa.Turma[0];
        Votar(mesa, jogador => jogador == inocente ? mesa.Impostor : inocente);
        var impostor = mesa.Impostor;

        mesa.Sala.Encerrar(mesa.Todos[0].Token);

        var premio = mesa.Sala.Visao(mesa.Todos[0].Token).Premios!.Single(p => p.Titulo == "Mestre do disfarce");
        Assert.Equal([impostor.Id], premio.Jogadores);
    }

    [Fact]
    public void ImpostorPrecisaDeQuatroPessoas()
    {
        var baralho = new Baralho([Pizza, new Carta("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 1")]);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Impostor, ModoDeJogo.EuNunca], true);

        for (var vez = 0; vez < 30; vez++)
            Assert.Equal(ModoDeJogo.EuNunca,
                baralho.Sortear(configuracao, new HashSet<string>(), 3, false, new Random(vez))!.Modo);
    }
}
