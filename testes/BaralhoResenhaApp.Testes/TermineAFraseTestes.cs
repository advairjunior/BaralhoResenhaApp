using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// ✍️ Termine a frase: a carta dá o começo, cada um completa em segredo, a turma
/// vota na melhor sem saber de quem é, e só a vencedora revela o autor.
/// </summary>
public sealed class TermineAFraseTestes
{
    private static readonly Carta Comeco =
        new("tf-1", ModoDeJogo.TermineAFrase, NivelDaCarta.Leve, "O pior lugar para um primeiro encontro é…");

    private sealed record Mesa(Sala Sala, Jogador Ana, Jogador Beto, Jogador Caio, Jogador Duda)
    {
        public Jogador[] Todos => [Ana, Beto, Caio, Duda];
        public int Rodada => Sala.Rodada!.Numero;
        public RodadaVisivel Visao(Jogador jogador) => Sala.Visao(jogador.Token).Rodada!;
        public void Escrever(Jogador jogador, string frase) => Sala.Responder(jogador.Token, Rodada, frase);

        /// <summary>Vota na frase de <paramref name="autor"/>, achando pelo texto que ele escreveu.</summary>
        public void VotarNaFraseDe(Jogador eleitor, string fraseDoAutor) =>
            Sala.Responder(eleitor.Token, Rodada, Visao(eleitor).Frases.ToList().IndexOf(fraseDoAutor).ToString());
    }

    private static Mesa Montar()
    {
        var sala = new Sala("ABCD", new Baralho([Comeco]), new Random(5));
        var ana = sala.Entrar("Ana", false);
        var beto = sala.Entrar("Beto", false);
        var caio = sala.Entrar("Caio", false);
        var duda = sala.Entrar("Duda", false);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.TermineAFrase], ZonaSegura: true));
        sala.Comecar(ana.Token);
        return new Mesa(sala, ana, beto, caio, duda);
    }

    private static Mesa TodosEscreveram()
    {
        var mesa = Montar();
        mesa.Escrever(mesa.Ana, "no velório");
        mesa.Escrever(mesa.Beto, "na fila do INSS");
        mesa.Escrever(mesa.Caio, "no churrasco da sogra");
        mesa.Escrever(mesa.Duda, "no rodízio de sushi");
        return mesa;
    }

    [Fact]
    public void EnquantoEscrevemNinguemVeAFraseDosOutros()
    {
        var mesa = Montar();

        mesa.Escrever(mesa.Ana, "no velório");

        Assert.True(mesa.Visao(mesa.Beto).Escrevendo);
        Assert.Empty(mesa.Visao(mesa.Beto).Frases);
        Assert.Null(mesa.Visao(mesa.Beto).MinhaResposta);
        Assert.Equal("no velório", mesa.Visao(mesa.Ana).MinhaResposta);
        Assert.Equal(1, mesa.Visao(mesa.Beto).Respostas);
        Assert.True(mesa.Sala.Visao(mesa.Beto.Token).Jogadores.Single(j => j.Id == mesa.Ana.Id).Respondeu);
    }

    [Fact]
    public void QuandoTodosEscrevemAsFrasesAparecemSemAutorParaVotar()
    {
        var mesa = TodosEscreveram();

        var visao = mesa.Visao(mesa.Beto);
        Assert.False(visao.Escrevendo);
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
        Assert.Equal(
            ["na fila do INSS", "no churrasco da sogra", "no rodízio de sushi", "no velório"],
            visao.Frases.Order());
        Assert.Equal("na fila do INSS", visao.Frases[visao.MinhaFrase!.Value]);
        Assert.Null(visao.MinhaResposta);
        Assert.Equal(0, visao.Respostas);
        Assert.All(mesa.Sala.Visao(mesa.Beto.Token).Jogadores, j => Assert.False(j.Respondeu));
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("uma frase que passa das quarenta letras sem dó")]
    public void FraseVaziaOuLongaNaoVale(string frase)
    {
        var mesa = Montar();

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Escrever(mesa.Ana, frase));
    }

    [Fact]
    public void NaoValeVotarNaPropria()
    {
        var mesa = TodosEscreveram();

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.VotarNaFraseDe(mesa.Ana, "no velório"));
        Assert.Equal("Não vale votar na sua.", erro.Message);
        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Responder(mesa.Ana.Token, mesa.Rodada, "9"));
    }

    [Fact]
    public void AMaisVotadaRevelaOAutorEAsOutrasContinuamAnonimas()
    {
        var mesa = TodosEscreveram();

        mesa.VotarNaFraseDe(mesa.Ana, "no churrasco da sogra");
        mesa.VotarNaFraseDe(mesa.Beto, "no churrasco da sogra");
        mesa.VotarNaFraseDe(mesa.Caio, "no velório");
        mesa.VotarNaFraseDe(mesa.Duda, "no churrasco da sogra");

        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        var revelacao = mesa.Visao(mesa.Ana).Revelacao!;
        var vencedora = revelacao.Frases[0];
        Assert.Equal(("no churrasco da sogra", 3, (Guid?)mesa.Caio.Id), (vencedora.Texto, vencedora.Votos, vencedora.Autor));
        Assert.All(revelacao.Frases.Skip(1), frase => Assert.Null(frase.Autor));
        Assert.Equal([mesa.Caio.Id], revelacao.Escolhidos);
        Assert.True(revelacao.Elogio);
        Assert.Empty(revelacao.JaFizeram);
        Assert.Empty(revelacao.Votos);
        // Quem ganhou distribui goles e ganha carta na manga.
        Assert.Contains(mesa.Visao(mesa.Ana).Pendentes, p => p.JogadorId == mesa.Caio.Id && p.Motivo == MotivoPendente.Elogio);
        Assert.Contains(mesa.Caio.Id, mesa.Sala.Rodada!.Ganharam);
    }

    [Fact]
    public void EmpateRevelaOsAutoresDasMaisVotadas()
    {
        var mesa = TodosEscreveram();

        mesa.VotarNaFraseDe(mesa.Ana, "no churrasco da sogra");
        mesa.VotarNaFraseDe(mesa.Beto, "no churrasco da sogra");
        mesa.VotarNaFraseDe(mesa.Caio, "no velório");
        mesa.VotarNaFraseDe(mesa.Duda, "no velório");

        var revelacao = mesa.Visao(mesa.Ana).Revelacao!;
        Assert.Equal(new[] { mesa.Ana.Id, mesa.Caio.Id }.Order(), revelacao.Escolhidos.Order());
        Assert.Equal(2, revelacao.Frases.Count(f => f.Autor is not null));
    }

    [Fact]
    public void QuemCriouASalaPassaParaAVotacaoSemEsperarTodoMundo()
    {
        var mesa = Montar();
        mesa.Escrever(mesa.Beto, "na fila do INSS");

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Revelar(mesa.Ana.Token, mesa.Rodada));
        Assert.Equal("Espere pelo menos 2 frases: com uma só, todo mundo sabe quem escreveu.", erro.Message);

        mesa.Escrever(mesa.Caio, "no churrasco da sogra");
        mesa.Sala.Revelar(mesa.Ana.Token, mesa.Rodada);

        Assert.False(mesa.Visao(mesa.Ana).Escrevendo);
        Assert.Equal(2, mesa.Visao(mesa.Ana).Frases.Count);
        Assert.Null(mesa.Visao(mesa.Ana).MinhaFrase);
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
    }

    [Fact]
    public void SoEntraNaMisturaComTresPessoasOuMais()
    {
        var baralho = new Baralho([Comeco, new Carta("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca")]);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca, ModoDeJogo.TermineAFrase], true);
        var sorteio = new Random(3);

        var comDois = Enumerable.Range(0, 100).Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), 2, false, sorteio)!.Modo);
        var comTres = Enumerable.Range(0, 100).Select(_ => baralho.Sortear(configuracao, new HashSet<string>(), 3, false, sorteio)!.Modo);

        Assert.DoesNotContain(ModoDeJogo.TermineAFrase, comDois);
        Assert.Contains(ModoDeJogo.TermineAFrase, comTres);
    }
}
