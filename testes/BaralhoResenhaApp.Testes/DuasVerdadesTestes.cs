using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// 🤥 Duas verdades e uma mentira: a pessoa da vez escreve três frases sobre si e
/// marca a mentira; a turma vota em segredo em qual é. Quem errou leva ponto; se
/// ninguém acertou, a pessoa da vez distribui goles.
/// </summary>
public sealed class DuasVerdadesTestes
{
    private static readonly Carta Viagens =
        new("dv-1", ModoDeJogo.DuasVerdades, NivelDaCarta.Leve, "{jogador}: duas verdades e uma mentira sobre viagens.");

    private static readonly string[] Frases = ["Já perdi um voo dormindo", "Já fui para o Japão", "Já dormi no aeroporto"];

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador DaVez => Todos.Single(j => j.Id == Sala.Rodada!.Alvo);
        public Jogador[] Turma => Todos.Where(j => j.Id != Sala.Rodada!.Alvo).ToArray();
        public int Rodada => Sala.Rodada!.Numero;
        public RodadaVisivel Visao(Jogador jogador) => Sala.Visao(jogador.Token).Rodada!;
        public void Escrever(int mentira = 1) => Sala.EscreverDuasVerdades(DaVez.Token, Rodada, Frases, mentira);
        public void Votar(Jogador jogador, int indice) => Sala.Responder(jogador.Token, Rodada, indice.ToString());
    }

    private static Mesa Montar()
    {
        var sala = new Sala("ABCD", new Baralho([Viagens]), new Random(8));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.DuasVerdades], ZonaSegura: true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void APessoaDaVezEhOJogadorDaCartaESoElaEscreve()
    {
        var mesa = Montar();

        Assert.Equal($"{mesa.DaVez.Nome}: duas verdades e uma mentira sobre viagens.", mesa.Sala.Rodada!.Texto);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.EscreverDuasVerdades(mesa.Turma[0].Token, mesa.Rodada, Frases, 0));
        Assert.Equal($"Quem escreve é {mesa.DaVez.Nome}.", erro.Message);
    }

    [Theory]
    [InlineData(new[] { "uma", "duas" }, 0)]
    [InlineData(new[] { "uma", "", "três" }, 0)]
    [InlineData(new[] { "uma", "duas", "três" }, 3)]
    [InlineData(new[] { "uma", "duas", "uma frase comprida demais que passa das sessenta letras sem dó" }, 0)]
    public void TresFrasesCurtasEUmaMentiraMarcada(string[] frases, int mentira)
    {
        var mesa = Montar();

        Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.EscreverDuasVerdades(mesa.DaVez.Token, mesa.Rodada, frases, mentira));
    }

    [Fact]
    public void AntesDeEscreverNinguemVota()
    {
        var mesa = Montar();

        Assert.Empty(mesa.Visao(mesa.Turma[0]).Afirmacoes);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Votar(mesa.Turma[0], 0));
        Assert.Equal($"Espere {mesa.DaVez.Nome} escrever as três frases.", erro.Message);
    }

    [Fact]
    public void AsFrasesAparecemParaTodosMasAMentiraSoParaQuemEscreveu()
    {
        var mesa = Montar();

        mesa.Escrever(mentira: 1);

        Assert.Equal(Frases, mesa.Visao(mesa.Turma[0]).Afirmacoes);
        Assert.Null(mesa.Visao(mesa.Turma[0]).MinhaMentira);
        Assert.Equal(1, mesa.Visao(mesa.DaVez).MinhaMentira);
        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Votar(mesa.DaVez, 0));
        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Votar(mesa.Turma[0], 3));
    }

    [Fact]
    public void QuemErrouLevaPontoEARevelacaoMostraAMentiraEOsVotos()
    {
        var mesa = Montar();
        mesa.Escrever(mentira: 1);
        var (acertou, errou1, errou2) = (mesa.Turma[0], mesa.Turma[1], mesa.Turma[2]);

        mesa.Votar(acertou, 1);
        mesa.Votar(errou1, 0);
        Assert.Null(mesa.Visao(acertou).Revelacao);
        mesa.Votar(errou2, 2);

        var revelacao = mesa.Visao(acertou).Revelacao!;
        Assert.Equal(1, revelacao.Mentira);
        Assert.Equal([1, 1, 1], revelacao.VotosNasAfirmacoes);
        Assert.Equal([acertou.Id], revelacao.Acertaram);
        Assert.Equal(new[] { errou1.Id, errou2.Id }.Order(), revelacao.Perderam.Order());
        Assert.False(revelacao.Elogio);
        Assert.Equal(0, acertou.Pontos);
        Assert.Equal(1, errou1.Pontos);
        Assert.Equal(0, mesa.DaVez.Pontos);
    }

    [Fact]
    public void NinguemAcertouAPessoaDaVezDistribuiEGanhaOPremio()
    {
        var mesa = Montar();
        mesa.Escrever(mentira: 2);

        foreach (var jogador in mesa.Turma) mesa.Votar(jogador, 0);

        var revelacao = mesa.Visao(mesa.DaVez).Revelacao!;
        Assert.Empty(revelacao.Acertaram);
        Assert.Equal(mesa.Turma.Length, revelacao.Perderam.Count);
        Assert.True(revelacao.Elogio);
        Assert.Equal([mesa.DaVez.Id], revelacao.Escolhidos);
        Assert.Contains(mesa.Visao(mesa.DaVez).Pendentes,
            p => p.JogadorId == mesa.DaVez.Id && p.Motivo == MotivoPendente.Elogio);
        Assert.Equal(1, mesa.DaVez.Estatisticas.MentirasPerfeitas);

        var premio = Assert.Single(PremiosDaNoite.Calcular(mesa.Todos, []), p => p.Titulo == "Mentiroso(a) de respeito");
        Assert.Equal([mesa.DaVez.Id], premio.Jogadores);
        Assert.Equal("Enganou a turma inteira 1 vez", premio.Descricao);
    }

    [Fact]
    public void DepoisDaRevelacaoACartaEsperaAPessoaDaVezContarAsHistorias()
    {
        var mesa = Montar();
        mesa.Escrever(mentira: 1);
        mesa.Votar(mesa.Turma[0], 1);
        mesa.Votar(mesa.Turma[1], 0);
        mesa.Votar(mesa.Turma[2], 0);

        Assert.Contains(mesa.Visao(mesa.Turma[0]).Pendentes,
            p => p.JogadorId == mesa.DaVez.Id && p.Motivo == MotivoPendente.Historia);
        Assert.Null(mesa.Visao(mesa.Turma[0]).PassaEmMs);

        // No ritmo Raiz, quem errou também tem que beber antes de a carta passar.
        mesa.Sala.MarcarPronto(mesa.Turma[1].Token, mesa.Rodada);
        mesa.Sala.MarcarPronto(mesa.Turma[2].Token, mesa.Rodada);
        Assert.Null(mesa.Visao(mesa.Turma[0]).PassaEmMs);

        mesa.Sala.MarcarPronto(mesa.DaVez.Token, mesa.Rodada);

        Assert.Empty(mesa.Visao(mesa.Turma[0]).Pendentes);
        Assert.NotNull(mesa.Visao(mesa.Turma[0]).PassaEmMs);
    }

    [Fact]
    public void QuemCriouASalaNaoRevelaAntesDasFrases()
    {
        var mesa = Montar();

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Revelar(mesa.Todos[0].Token, mesa.Rodada));
        Assert.Equal($"Espere {mesa.DaVez.Nome} escrever as três frases.", erro.Message);

        mesa.Escrever();
        mesa.Votar(mesa.Turma[0], 1);
        mesa.Sala.Revelar(mesa.Todos[0].Token, mesa.Rodada);
        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
    }

    [Fact]
    public void SoEntraNaMisturaComTresPessoasOuMais()
    {
        var baralho = new Baralho([Viagens, new Carta("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca")]);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca, ModoDeJogo.DuasVerdades], true);
        var sorteio = new Random(3);

        var comDois = Enumerable.Range(0, 100).Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), 2, false, sorteio)!.Modo);
        var comTres = Enumerable.Range(0, 100).Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), 3, false, sorteio)!.Modo);

        Assert.DoesNotContain(ModoDeJogo.DuasVerdades, comDois);
        Assert.Contains(ModoDeJogo.DuasVerdades, comTres);
    }
}
