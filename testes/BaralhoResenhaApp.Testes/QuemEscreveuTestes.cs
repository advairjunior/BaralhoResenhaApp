using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// ✍️ Quem escreveu?: a carta faz uma pergunta pessoal e cada um responde em
/// segredo. As respostas aparecem sem autor, uma vai para o centro e todo mundo
/// vota em quem escreveu (quem escreveu vota também, para não se entregar).
/// Errou, leva ponto; ninguém acertou, quem escreveu escapou e ganha carta na manga.
/// </summary>
public sealed class QuemEscreveuTestes
{
    private static readonly Carta ComidaEstranha = new("qe-1", ModoDeJogo.QuemEscreveu, NivelDaCarta.Leve,
        "A comida mais estranha que você já comeu");

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public int Rodada => Sala.Rodada!.Numero;
        public RodadaVisivel Visao(Jogador jogador) => Sala.Visao(jogador.Token).Rodada!;
        public void Responder(Jogador jogador, string resposta) => Sala.Responder(jogador.Token, Rodada, resposta);
        public Jogador Autor => Todos.Single(j => j.Id == Sala.Rodada!.OrdemDasFrases![Sala.Rodada.FraseEmJogo!.Value]);
    }

    private static Mesa Montar(int pessoas = 4)
    {
        var sala = new Sala("ABCD", new Baralho([ComidaEstranha]), new Random(9));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Take(pessoas).Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.QuemEscreveu], ZonaSegura: true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    private static Mesa TodoMundoEscreveu()
    {
        var mesa = Montar();
        string[] respostas = ["Formiga", "Jacaré", "Escargot", "Pizza de banana"];
        foreach (var (jogador, resposta) in mesa.Todos.Zip(respostas)) mesa.Responder(jogador, resposta);
        return mesa;
    }

    [Fact]
    public void EscreverEmSegredoEDepoisUmaRespostaVaiProCentro()
    {
        var mesa = Montar();
        mesa.Responder(mesa.Todos[0], "  Formiga  ");
        Assert.True(mesa.Visao(mesa.Todos[1]).Escrevendo);
        Assert.Empty(mesa.Visao(mesa.Todos[1]).Frases);

        foreach (var (jogador, resposta) in mesa.Todos.Skip(1).Zip(["Jacaré", "Escargot", "Pizza de banana"]))
            mesa.Responder(jogador, resposta);

        var rodada = mesa.Visao(mesa.Todos[1]);
        Assert.False(rodada.Escrevendo);
        Assert.Equal(4, rodada.Frases.Count);
        Assert.Contains("Formiga", rodada.Frases);
        Assert.InRange(rodada.FraseEmJogo!.Value, 0, 3);
        Assert.Equal(0, rodada.Respostas);
    }

    [Fact]
    public void ComMenosDeTresRespostasNaoDaParaIrPraVotacao()
    {
        var mesa = Montar();
        mesa.Responder(mesa.Todos[1], "Formiga");
        mesa.Responder(mesa.Todos[2], "Jacaré");

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Revelar(mesa.Todos[0].Token, mesa.Rodada));
        Assert.Equal("Espere pelo menos 3 respostas: com menos, fica fácil saber quem escreveu.", erro.Message);
    }

    [Fact]
    public void VotaEmAlguemDaSalaMenosEmSiMesmo()
    {
        var mesa = TodoMundoEscreveu();
        var ana = mesa.Todos[0];

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Responder(ana, ana.Id.ToString()));
        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Responder(ana, "Formiga"));
        Assert.Equal("Vote em quem você acha que escreveu.", erro.Message);
    }

    [Fact]
    public void QuemErrouLevaPontoEQuemEscreveuNaoContaNaVotacao()
    {
        var mesa = TodoMundoEscreveu();
        var autor = mesa.Autor;
        var outros = mesa.Todos.Where(j => j != autor).ToArray();
        var errado = outros[2];

        // Quem escreveu vota também, num chute qualquer, para não se entregar.
        mesa.Responder(autor, outros[0].Id.ToString());
        mesa.Responder(outros[0], autor.Id.ToString());
        mesa.Responder(outros[1], autor.Id.ToString());
        mesa.Responder(errado, outros[0].Id.ToString());

        var revelacao = mesa.Visao(autor).Revelacao!;
        Assert.Equal([errado.Id], revelacao.Perderam);
        Assert.Equal(new[] { outros[0].Id, outros[1].Id }.Order(), revelacao.Acertaram.Order());
        Assert.Empty(revelacao.Escolhidos);
        Assert.Equal(1, errado.Pontos);
        Assert.Equal(0, autor.Pontos);
        // Só a resposta do centro revela quem escreveu.
        Assert.Equal(autor.Id, Assert.Single(revelacao.Frases, f => f.Autor is not null).Autor);
    }

    [Fact]
    public void NinguemAcertouQuemEscreveuEscapaEGanhaCartaNaManga()
    {
        var mesa = TodoMundoEscreveu();
        var autor = mesa.Autor;
        var outros = mesa.Todos.Where(j => j != autor).ToArray();
        var mao = autor.Mao.Count;

        mesa.Responder(autor, outros[0].Id.ToString());
        mesa.Responder(outros[0], outros[1].Id.ToString());
        mesa.Responder(outros[1], outros[2].Id.ToString());
        mesa.Responder(outros[2], outros[0].Id.ToString());

        var revelacao = mesa.Visao(autor).Revelacao!;
        Assert.Equal([autor.Id], revelacao.Escolhidos);
        Assert.True(revelacao.Elogio);
        Assert.Equal(3, revelacao.Perderam.Count);
        Assert.Equal(mao + 1, autor.Mao.Count);
    }

    [Fact]
    public void PrecisaDeTresPessoas()
    {
        var baralho = new Baralho([ComidaEstranha]);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.QuemEscreveu], true);

        Assert.Null(baralho.Sortear(configuracao, new HashSet<string>(), 2, false, new Random(1)));
    }

    [Fact]
    public void BancoTemPerguntasPessoais()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Modo == ModoDeJogo.QuemEscreveu).ToList();

        Assert.True(cartas.Count >= 40, $"só {cartas.Count} cartas");
        Assert.All(cartas, c => Assert.StartsWith("qe-", c.Id));
    }
}
